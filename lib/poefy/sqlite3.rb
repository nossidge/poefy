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

    # This is the type of database that is being used.
    # It is also used as a signifier that a database has been specified.
    def db_type
      'sqlite3'
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

  end

end

################################################################################
