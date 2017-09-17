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

      # Create the stored procedures in the database.
      def create_sprocs sprocs
        sprocs.each do |key, value|
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
