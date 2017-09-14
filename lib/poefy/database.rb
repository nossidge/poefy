#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Class for connecting to a sqlite3 database.
################################################################################

require 'sqlite3'

require_relative 'string_manipulation.rb'
require_relative 'handle_error.rb'

################################################################################

module Poefy

  class Database

    include Poefy::StringManipulation
    include Poefy::HandleError

    attr_reader :console, :db_file

    # Finalizer must be a class variable.
    @@final = proc { |dbase, sproc| proc {
      sproc.each { |k, v| v.close }
      dbase.close if dbase
    } }

    def initialize db_file, console = false
      @db_file = db_file
      @console = console
      @sproc = {}
      db
      ObjectSpace.define_finalizer(self, @@final.call(@db, @sproc))
    end

    # Open instance database session, if not already existing.
    # This is called in all methods where it is needed. So no need to
    #   execute it before any calling code.
    def db
      if not @db
        if !exists?
          @db = nil
        else
          begin
            @db = SQLite3::Database.open(@db_file)
            @db.results_as_hash = true
          rescue
            @db = nil
            return handle_error 'ERROR: Database contains invalid structure'
          end
          create_sprocs 'lines'
        end
      end
      @db
    end

    # Close the database file.
    def close
      @sproc.each { |k, v| v.close rescue nil }
      @db.close if @db
      @db = nil
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
      table_name = 'lines'

      # Delete any existing database.
      File.delete(@db_file) if File.exists?(@db_file)

      # Create a new database.
      @db = SQLite3::Database.new(@db_file)

      # Create the lines table and the index.
      create_table table_name

      # Convert the lines array into an expanded array of rhyme metadata.
      import_data = lines_rhyme_metadata lines

      # Import the data.
      db.transaction do |db_tr|
        import_data.each do |line|
          db_tr.execute "INSERT INTO #{table_name} VALUES ( ?, ?, ?, ? )", line
        end
      end
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
    # Use instance variables to keep a cache of the results.
    def sproc_rhymes_all! rhyme_count, syllable_min_max = nil
      db
      @rbc = Hash.new { |h,k| h[k] = {} } if @rbc.nil?
      if @rbc[rhyme_count][syllable_min_max].nil?
        @rbc[rhyme_count][syllable_min_max] = if syllable_min_max
          sproc_rhymes_by_count_syllables(rhyme_count, syllable_min_max)
        else
          sproc_rhymes_by_count(rhyme_count)
        end
      end
      @rbc[rhyme_count][syllable_min_max].dup
    end
    def sproc_lines_all! rhyme, syllable_min_max = nil
      db
      @la = Hash.new { |h,k| h[k] = {} } if @la.nil?
      if @la[rhyme][syllable_min_max].nil?
        @la[rhyme][syllable_min_max] = if syllable_min_max
          sproc_lines_all_syllables(rhyme, syllable_min_max)
        else
          sproc_lines_all(rhyme)
        end
      end
      @la[rhyme][syllable_min_max].dup
    end

    private

      # Create the table and the index.
      def create_table table_name
        db.execute <<-SQL
          CREATE TABLE #{table_name} (
            line        TEXT,
            syllables   SMALLINT,
            final_word  TEXT,
            rhyme       TEXT
          );
        SQL
        db.execute <<-SQL
          CREATE INDEX idx ON #{table_name} (
            rhyme, final_word, line
          );
        SQL
      end

      # For each line, figure out the needed rhyme metadata.
      # Output is an array: [line, final_word, rhyme, syllables]
      def lines_rhyme_metadata lines
        output = []
        lines.map do |line|

          # Don't add the line if it contains a blacklisted? substring.
          next if Wordfilter.blacklisted? line

          # Get the phrase info for the line.
          phrase = phrase_info line
          syll   = phrase[:syllables]
          rhymes = phrase[:rhymes]
          final  = phrase[:last_word]

          # There may be more than one rhyme, so add a database
          #   record for each rhyme.
          rhymes.each do |rhyme|
            output << [line, syll, final, rhyme]
          end
        end

        output
      end

      ##########################################################################

      # Define all stored procedures.
      def create_sprocs table_name
        sql = {}
        sql[:rbc] = %Q[
          SELECT rhyme, COUNT(rhyme) AS rc
          FROM (
            SELECT rhyme, final_word, COUNT(final_word) AS wc
            FROM #{table_name}
            GROUP BY rhyme, final_word
          )
          GROUP BY rhyme
          HAVING rc >= ?
        ]
        sql[:rbcs] = %Q[
          SELECT rhyme, COUNT(rhyme) AS rc
          FROM (
            SELECT rhyme, final_word, COUNT(final_word) AS wc
            FROM #{table_name}
            WHERE syllables BETWEEN ? AND ?
            GROUP BY rhyme, final_word
          )
          GROUP BY rhyme
          HAVING rc >= ?
        ]
        sql[:la] = %Q[
          SELECT line, syllables, final_word, rhyme
          FROM #{table_name} WHERE rhyme = ?
        ]
        sql[:las] = %Q[
          SELECT line, syllables, final_word, rhyme
          FROM #{table_name} WHERE rhyme = ?
          AND syllables BETWEEN ? AND ?
        ]
        sql.each do |key, value|
          begin
            @sproc[key] = db.prepare value
          rescue
            raise 'ERROR: Database table structure is invalid'
            return handle_error 'ERROR: Database table structure is invalid'
          end
        end
      end

      # Find rhymes and counts greater than a certain length.
      def sproc_rhymes_by_count rhyme_count
        @sproc[:rbc].reset!
        @sproc[:rbc].bind_param(1, rhyme_count)
        @sproc[:rbc].execute.to_a
      end

      # Also adds syllable selection.
      def sproc_rhymes_by_count_syllables rhyme_count, syllable_min_max
        @sproc[:rbcs].reset!
        @sproc[:rbcs].bind_param(1, syllable_min_max[:min])
        @sproc[:rbcs].bind_param(2, syllable_min_max[:max])
        @sproc[:rbcs].bind_param(3, rhyme_count)
        @sproc[:rbcs].execute.to_a
      end

      # Find all lines for a certain rhyme.
      def sproc_lines_all rhyme
        @sproc[:la].reset!
        @sproc[:la].bind_param(1, rhyme)
        @sproc[:la].execute.to_a
      end

      # Also adds syllable selection.
      def sproc_lines_all_syllables rhyme, syllable_min_max
        @sproc[:las].reset!
        @sproc[:las].bind_param(1, rhyme)
        @sproc[:las].bind_param(2, syllable_min_max[:min])
        @sproc[:las].bind_param(3, syllable_min_max[:max])
        @sproc[:las].execute.to_a
      end

      ##########################################################################

  end

end

################################################################################
