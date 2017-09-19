#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Extend 'Database' class for connecting to a PostgreSQL database.
# These methods are specific to PostgreSQL.
# Other databases should be implemented in separate gems.
################################################################################

require 'pg'

################################################################################

module Poefy

  class Database

    # This is the type of database that is being used.
    # It is also used as a signifier that a database has been specified.
    def db_type
      'pg'
    end

    private

      # The name of the table.
      def db_table_name
        @name
      end

      # Create a new table.
      def db_new
        db_open
      end

      # Open a connection to the database.
      def db_open
        @db ||= PG.connect(
          :dbname   => 'poefy',
          :user     => 'poefy',
          :password => 'poefy'
        )
      end

      # See if the table exists or not.
      # ToDo
      def db_exists?
        db_open
        begin
          @db.exec("SELECT count(*) FROM #{db_table_name};")
          true
        rescue PG::UndefinedTable
          false
        end
      end

      # Execute a query.
      def db_execute! sql
        db.exec sql
      end

      # Insert an array of lines.
      def db_insert_rows table_name, rows
        sql = "INSERT INTO #{table_name} VALUES ( $1, $2, $3, $4 )"
        db.transaction do |db_tr|
          rows.each do |line|
            db_tr.exec sql, line
          end
        end
      end

      ##########################################################################

      # Create the table and the index.
      def create_table table_name
        index_name = 'idx_' + table_name
        db_execute! <<-SQL
          SET client_min_messages TO WARNING;
          DROP INDEX IF EXISTS #{index_name};
          DROP TABLE IF EXISTS #{table_name};
          CREATE TABLE #{table_name} (
            line        TEXT,
            syllables   SMALLINT,
            final_word  TEXT,
            rhyme       TEXT
          );
          CREATE INDEX #{index_name} ON #{table_name} (
            rhyme, final_word, line
          );
        SQL
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
          ) AS sub_table
          GROUP BY rhyme
          HAVING COUNT(rhyme) >= $1
        SQL
        sql[:rbcs] = <<-SQL
          SELECT rhyme, COUNT(rhyme) AS rc
          FROM (
            SELECT rhyme, final_word, COUNT(final_word) AS wc
            FROM #{db_table_name}
            WHERE syllables BETWEEN $1 AND $2
            GROUP BY rhyme, final_word
          ) AS sub_table
          GROUP BY rhyme
          HAVING COUNT(rhyme) >= $3
        SQL
        sql[:la] = <<-SQL
          SELECT line, syllables, final_word, rhyme
          FROM #{db_table_name} WHERE rhyme = $1
        SQL
        sql[:las] = <<-SQL
          SELECT line, syllables, final_word, rhyme
          FROM #{db_table_name} WHERE rhyme = $1
          AND syllables BETWEEN $2 AND $3
        SQL
        sql
      end

      # Create the stored procedures in the database.
      def create_sprocs sprocs_hash
        sprocs_hash.each do |key, value|
          begin
            db.prepare key.to_s, value
          rescue
            raise 'ERROR: Database table structure is invalid'
            return handle_error 'ERROR: Database table structure is invalid'
          end
        end
      end

      # Find rhymes and counts greater than a certain length.
      def sproc_rhymes_by_count rhyme_count
        rs = db.exec_prepared 'rbc', [rhyme_count]
        rs.values.map do |row|
          {
            'rhyme' => row[0],
            'rc'    => row[1].to_i
          }
        end
      end

      # Also adds syllable selection.
      def sproc_rhymes_by_count_syllables rhyme_count, syllable_min_max
        arg_array = [
          syllable_min_max[:min],
          syllable_min_max[:max],
          rhyme_count
        ]
        rs = db.exec_prepared 'rbcs', arg_array
        rs.values.map do |row|
          {
            'rhyme' => row[0],
            'rc'    => row[1].to_i
          }
        end
      end

      # Find all lines for a certain rhyme.
      def sproc_lines_all rhyme
        rs = db.exec_prepared 'la', [rhyme]
        rs.values.map do |row|
          {
            'line'       => row[0],
            'syllables'  => row[1].to_i,
            'final_word' => row[2],
            'rhyme'      => row[3]
          }
        end
      end

      # Also adds syllable selection.
      def sproc_lines_all_syllables rhyme, syllable_min_max
        arg_array = [
          rhyme,
          syllable_min_max[:min],
          syllable_min_max[:max]
        ]
        rs = db.exec_prepared 'las', arg_array
        rs.values.map do |row|
          {
            'line'       => row[0],
            'syllables'  => row[1].to_i,
            'final_word' => row[2],
            'rhyme'      => row[3]
          }
        end
      end

  end

end

################################################################################
