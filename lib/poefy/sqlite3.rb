#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Extend 'Database' class for connecting to a sqlite3 database.
# These methods are specific to sqlite3.
# Other databases should be implemented in separate gems.
################################################################################

require 'sqlite3'

################################################################################

module Poefy

  class Database

    # Open a connection, execute a query, close the connection.
    def self.single_exec! database_name, sql
      path = Database::path database_name
      con = SQLite3::Database.open path
      rs = con.execute sql
      con.close
      rs
    end

    # List all database files in the directory.
    # Does not include databases used for testing.
    def self.list
      Dir[Poefy.root + '/data/*.db'].map do |i|
        File.basename(i, '.db')
      end.reject do |i|
        i.start_with?('spec_')
      end.sort - ['test']
    end

    # Get the description of a database.
    def self.desc database_name
      begin
        sql = "SELECT comment FROM comment;"
        Database::single_exec!(database_name, sql).flatten.first
      rescue
        ''
      end
    end

    # List all database files and their descriptions.
    def self.list_with_desc
      Database::list.map do |i|
        begin
          [i, Database::desc(i)]
        rescue
          [i, '']
        end
      end.to_h
    end

    # Get the path of a database.
    def self.path database_name
      Poefy.root + '/data/' + File.basename(database_name, '.db') + '.db'
    end

    ############################################################################

    # This is the type of database that is being used.
    # It is also used as a signifier that a database has been specified.
    def type
      'sqlite3'
    end

    # Get/set the description of the database.
    def desc
      Database::desc @name
    end
    def desc=(description)
      execute! "DELETE FROM comment;"
      execute! "INSERT INTO comment VALUES ( ? );", description.to_s
    end

    # The number of lines in the table.
    def count
      return 0 if not exists?
      sql = "SELECT COUNT(*) AS num FROM #{table};"
      execute!(sql).first['num'].to_i
    end

    # See if the database file exists or not.
    def exists?
      File.exists?(db_file)
    end

    # Get all rhyming lines for the word.
    def rhymes word, key = nil
      return nil if word.nil?

      sql = <<-SQL
        SELECT rhyme, final_word, syllables, line
        FROM lines
        WHERE rhyme = ?
        ORDER BY rhyme, final_word, syllables, line
      SQL
      output = word.to_phrase.rhymes.keys.map do |rhyme|
        rs = execute!(sql, [rhyme]).to_a
        rs.each{ |a| a.reject!{ |k| k.is_a? Numeric }}
      end.flatten

      if !key.nil? and %w[rhyme final_word syllables line].include?(key)
        output.map!{ |i| i[key] }
      end
      output
    end

    private

      # The name of the table.
      def table
        'lines'
      end

      # Create a new database.
      def new_connection
        File.delete(db_file) if File.exists?(db_file)
        @db = SQLite3::Database.new(db_file)
        @db.results_as_hash = true
      end

      # Open a connection to the database.
      def open_connection
        @db = SQLite3::Database.open(db_file)
        @db.results_as_hash = true
      end

      # Execute a query.
      def execute! sql, *args
        db.execute sql, *args
      end

      # Insert an array of poefy-described lines.
      def insert_lines table_name, rows
        sql = "INSERT INTO #{table_name} VALUES ( ?, ?, ?, ? )"
        db.transaction do |db_tr|
          rows.each do |line|
            db_tr.execute sql, line
          end
        end
      end

      ##########################################################################

      # Find the correct database file.
      # If local, just use the value.
      # Else, use the database in /data/ directory.
      def db_file
        if @local
          @name
        elsif @db_file
          @db_file
        else
          path = Poefy.root + '/data'
          file = File.basename(@name, '.db')
          @db_file = path + '/' + file + '.db'
        end
      end

      ##########################################################################

      # Create the table and the index.
      def create_table table_name, description = nil
        execute! <<-SQL
          CREATE TABLE #{table_name} (
            line        TEXT,
            syllables   SMALLINT,
            final_word  TEXT,
            rhyme       TEXT
          );
        SQL
        execute! <<-SQL
          CREATE TABLE comment (
            comment     TEXT
          );
        SQL
        execute! <<-SQL
          CREATE INDEX idx ON #{table_name} (
            rhyme, final_word, line
          );
        SQL
        self.desc = description
      end

      ##########################################################################

      # Define SQL of the stored procedures.
      def sprocs_sql_hash
        sql = {}
        sql[:rbc] = <<-SQL
          SELECT rhyme, COUNT(rhyme) AS count
          FROM (
            SELECT rhyme, final_word, COUNT(final_word) AS wc
            FROM #{table}
            GROUP BY rhyme, final_word
          )
          GROUP BY rhyme
          HAVING count >= ?
        SQL
        sql[:rbcs] = <<-SQL
          SELECT rhyme, COUNT(rhyme) AS count
          FROM (
            SELECT rhyme, final_word, COUNT(final_word) AS wc
            FROM #{table}
            WHERE syllables BETWEEN ? AND ?
            GROUP BY rhyme, final_word
          )
          GROUP BY rhyme
          HAVING count >= ?
        SQL
        sql[:la] = <<-SQL
          SELECT line, syllables, final_word, rhyme
          FROM #{table} WHERE rhyme = ?
        SQL
        sql[:las] = <<-SQL
          SELECT line, syllables, final_word, rhyme
          FROM #{table} WHERE rhyme = ?
          AND syllables BETWEEN ? AND ?
        SQL
        sql
      end

      # Create the stored procedures in the database.
      def create_sprocs
        sprocs_sql_hash.each do |key, value|
          @sproc[key] = db.prepare value
        end
      rescue
        handle_error \
          "ERROR: Database table structure is invalid.\n" +
          "       Please manually DROP the corrupt table and recreate it."
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
      def sproc_lines_by_rhyme rhyme
        @sproc[:la].reset!
        @sproc[:la].bind_param(1, rhyme)
        @sproc[:la].execute.to_a
      end

      # Also adds syllable selection.
      def sproc_lines_by_rhyme_syllables rhyme, syllable_min_max
        @sproc[:las].reset!
        @sproc[:las].bind_param(1, rhyme)
        @sproc[:las].bind_param(2, syllable_min_max[:min])
        @sproc[:las].bind_param(3, syllable_min_max[:max])
        @sproc[:las].execute.to_a
      end

  end

end

################################################################################
