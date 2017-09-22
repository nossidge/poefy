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
      end - ['test']
    end

    # Get the description of a database.
    def self.desc database_name
      sql = "SELECT comment FROM comment;"
      Database::single_exec!(database_name, sql).flatten.first
    end

    # List all database files and their descriptions.
    def self.list_with_desc
      Database::list.map do |i|
        begin
          [i, Database::desc(i)]
        rescue
          [i, '']
        end
      end
    end

    # Get the path of a database.
    def self.path database_name
      Poefy.root + '/data/' + database_name + '.db'
    end

    ############################################################################

    # This is the type of database that is being used.
    # It is also used as a signifier that a database has been specified.
    def db_type
      'sqlite3'
    end

    # Get/set the description of the database.
    def desc
      Database::desc @name
    end
    def desc=(description)
      db.execute "DELETE FROM comment;"
      db.execute "INSERT INTO comment VALUES ( ? );", description.to_s
    end

    private

      # The name of the table.
      def db_table_name
        'lines'
      end

      # Create a new database.
      def db_new
        File.delete(db_file) if File.exists?(db_file)
        @db = SQLite3::Database.new(db_file)
      end

      # Open a connection to the database.
      def db_open
        @db = SQLite3::Database.open(db_file)
        @db.results_as_hash = true
      end

      # See if the database file exists or not.
      def db_exists?
        File.exists?(db_file)
      end

      # Execute a query.
      def db_execute! sql
        db.execute sql
      end

      # Insert an array of lines.
      def db_insert_rows table_name, rows
        db.transaction do |db_tr|
          rows.each do |line|
            db_tr.execute "INSERT INTO #{table_name} VALUES ( ?, ?, ?, ? )", line
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
        db_execute! <<-SQL
          CREATE TABLE #{table_name} (
            line        TEXT,
            syllables   SMALLINT,
            final_word  TEXT,
            rhyme       TEXT
          );
        SQL
        db_execute! <<-SQL
          CREATE TABLE comment (
            comment     TEXT
          );
        SQL
        db_execute! <<-SQL
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
          SELECT rhyme, COUNT(rhyme) AS rc
          FROM (
            SELECT rhyme, final_word, COUNT(final_word) AS wc
            FROM #{db_table_name}
            GROUP BY rhyme, final_word
          )
          GROUP BY rhyme
          HAVING rc >= ?
        SQL
        sql[:rbcs] = <<-SQL
          SELECT rhyme, COUNT(rhyme) AS rc
          FROM (
            SELECT rhyme, final_word, COUNT(final_word) AS wc
            FROM #{db_table_name}
            WHERE syllables BETWEEN ? AND ?
            GROUP BY rhyme, final_word
          )
          GROUP BY rhyme
          HAVING rc >= ?
        SQL
        sql[:la] = <<-SQL
          SELECT line, syllables, final_word, rhyme
          FROM #{db_table_name} WHERE rhyme = ?
        SQL
        sql[:las] = <<-SQL
          SELECT line, syllables, final_word, rhyme
          FROM #{db_table_name} WHERE rhyme = ?
          AND syllables BETWEEN ? AND ?
        SQL
        sql
      end

      # Create the stored procedures in the database.
      def create_sprocs sprocs_hash
        sprocs_hash.each do |key, value|
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

  end

end

################################################################################
