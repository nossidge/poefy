#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Class for connecting to a sqlite3 database.
################################################################################

require 'sqlite3'
require 'tempfile'

require_relative 'string_manipulation.rb'
require_relative 'handle_error.rb'

################################################################################

module Poefy

  class Database

    include Poefy::StringManipulation
    include Poefy::HandleError

    attr_reader :console, :db_file

    # Finalizer must be a class variable.
    @@final = proc { |dbase| proc {
      @sproc_lines_all.close if @sproc_lines_all
      @sproc_rhymes_by_count.close if @sproc_rhymes_by_count
      @sproc_rhymes_by_count_syllables.close if @sproc_rhymes_by_count_syllables
      dbase.close if dbase
    } }

    def initialize db_file, console = false
      @db_file = db_file
      @console = console
      ObjectSpace.define_finalizer(self, @@final.call(@db))
    end

    # Open global database session, if not already existing.
    # This is called in all methods where it is needed. So no need to
    #   execute it before any calling code.
    def db
      if not @db
        begin
          open
        rescue
          @db = nil
          return handle_error 'ERROR: Database does not yet exist'
        end
      end
      @db
    end

    # Open the database file.
    def open
      @db = SQLite3::Database.open(@db_file)
      @db.results_as_hash = true

      # Create a REGEX function in SQLite.
      # http://stackoverflow.com/questions/7302311
      @db.create_function('regexp', 2) do |func, pattern, expression|
        regexp = Regexp.new(pattern.to_s, Regexp::IGNORECASE)
        func.result = expression.to_s.match(regexp) ? 1 : 0
      end
    end

    # Close the database file.
    def close
      @sproc_lines_all.close if @sproc_lines_all
      @sproc_rhymes_by_count.close if @sproc_rhymes_by_count
      @sproc_rhymes_by_count_syllables.close if @sproc_rhymes_by_count_syllables
      db.close
    end

    # See if the database file exists or not.
    def exists?
      File.exists?(@db_file)
    end

    # Creates a database with the correct format.
    #   Convert input lines array to SQL import format file.
    #   Delete database if already exists.
    #   Create database using SQL import file.
    #   Delete both files.
    def make_new lines
      make_new!(lines) if !exists?
    end

    # Force new database, overwriting existing.
    def make_new! lines

      # Convert the lines array into an import file.
      sql_import_file = save_sql_import_file lines

      # Delete any existing database.
      File.delete(@db_file) rescue nil

      # Write SQL and SQLite instructions to temp file,
      #   import to database, delete temp file.
      # The SQL file is finicky. Each line requires no leading whitespace.
      sql_instruction_file = tmpfile
      sql = %Q[
        CREATE TABLE IF NOT EXISTS lines (
          line TEXT, syllables INT, final_word TEXT, rhyme TEXT
        );
        CREATE INDEX idx ON lines (rhyme, final_word, line);
        .separator "\t"
        .import #{sql_import_file} lines
      ].split("\n").map(&:strip).join("\n")
      File.open(sql_instruction_file, 'w') { |fo| fo.write sql }

      # Create the database using the SQL instructions.
      `sqlite3 #{@db_file} < #{sql_instruction_file}`

      # Delete temporary files.
      File.delete sql_instruction_file
      File.delete sql_import_file
    end

    # Execute an SQL request.
    def execute! sql
      begin
        db.execute sql
      rescue
        return handle_error 'ERROR: Database has incorrect table structure', []
      end
    end

    # Format a string for SQL.
    def format_sql_string string
      string.gsub('"','""')
    end

    # Public interfaces for private stored procedure methods.
    def sproc_rhymes_all! rhyme_count, syllable_min_max = nil
      if syllable_min_max
        sproc_rhymes_by_count_syllables rhyme_count, syllable_min_max
      else
        sproc_rhymes_by_count rhyme_count
      end
    end
    def sproc_lines_all! rhyme
      sproc_lines_all rhyme
    end

    private

      # Turn an array of string lines into an SQL import file.
      # Format is "line, final_word, rhyme, syllables"
      # Use tabs as delimiters.
      def save_sql_import_file lines
        sql_lines = []
        lines.map do |line|
          next if Wordfilter.blacklisted? line
          line_ = format_sql_string line
          final = line.to_phrase.last_word.downcase rescue ''

          final_ = format_sql_string final
          syll = syllables line
          get_rhymes(line).each do |rhyme|
            rhyme_ = format_sql_string rhyme
            sql_lines << "\"#{line_}\"\t#{syll}\t\"#{final_}\"\t\"#{rhyme_}\""
          end
        end
        sql_file = tmpfile
        File.open(sql_file, 'w') { |fo| fo.puts sql_lines }
        sql_file
      end

      # Generate a random temporary file.
      def tmpfile
        Dir::Tmpname.make_tmpname ['tmp-','.txt'], nil
      end

      ##########################################################################

      # Find rhymes and counts greater than a certain length.
      def sproc_rhymes_by_count rhyme_count
        if not @sproc_rhymes_by_count
          sql = %Q[
            SELECT rhyme, COUNT(rhyme) AS rc
            FROM (
              SELECT rhyme, final_word, COUNT(final_word) AS wc
              FROM lines
              GROUP BY rhyme, final_word
            )
            GROUP BY rhyme
            HAVING rc >= ?
          ]
          begin
            @sproc_rhymes_by_count = db.prepare sql
          rescue
            return handle_error 'ERROR: Database table structure is invalid'
          end
        end
        @sproc_rhymes_by_count.reset!
        @sproc_rhymes_by_count.bind_param(1, rhyme_count)
        @sproc_rhymes_by_count.execute.to_a
      end

      # Also adds syllable selection.
      def sproc_rhymes_by_count_syllables rhyme_count, syllable_min_max
        if not @sproc_rhymes_by_count_syllables
          sql = %Q[
            SELECT rhyme, COUNT(rhyme) AS rc
            FROM (
              SELECT rhyme, final_word, COUNT(final_word) AS wc
              FROM lines
              WHERE syllables BETWEEN ? AND ?
              GROUP BY rhyme, final_word
            )
            GROUP BY rhyme
            HAVING rc >= ?
          ]
          begin
            @sproc_rhymes_by_count_syllables = db.prepare sql
          rescue
            return handle_error 'ERROR: Database table structure is invalid'
          end
        end
        @sproc_rhymes_by_count_syllables.reset!
        @sproc_rhymes_by_count_syllables.bind_param(1, syllable_min_max[:min])
        @sproc_rhymes_by_count_syllables.bind_param(2, syllable_min_max[:max])
        @sproc_rhymes_by_count_syllables.bind_param(3, rhyme_count)
        @sproc_rhymes_by_count_syllables.execute.to_a
      end

      ##########################################################################

      # Find all lines for a certain rhyme.
      def sproc_lines_all rhyme
        if not @sproc_lines_all
          sql = %Q[
            SELECT line, syllables, final_word, rhyme
            FROM lines WHERE rhyme = ?
          ]
          begin
            @sproc_lines_all = db.prepare sql
          rescue
            return handle_error 'ERROR: Database table structure is invalid'
          end
        end
        @sproc_lines_all.reset!
        @sproc_lines_all.bind_param(1, rhyme)
        @sproc_lines_all.execute.to_a
      end

  end

end

################################################################################
