#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Base class for connecting to a database.
# Install gem 'poefy-sqlite3' or 'poefy-pg' for implementation.
################################################################################

require_relative 'string_manipulation.rb'

################################################################################

module Poefy

  class Database

    include Poefy::StringManipulation

    attr_reader :name, :local

    def initialize name, local = false
      @local = local
      @name = name.to_s
      @sproc = {}
      type
      db
    end

    ############################################################################

    # Validate that a database type has been required.
    # This will be overwritten by a database-specific method,
    #   so raise an error if no database has been specified yet.
    # Due to the way 'bin/poefy' is set up, that code will fail before
    #   this point is reached, so this error is only from Ruby calls.
    def type
      msg = "No database interface specified. " +
            "Please require 'poefy/sqlite3' or 'poefy/pg'"
      raise LoadError, msg
    end

    # Open instance database session, if not already existing.
    def db
      if not @db and exist?
        begin
          open_connection
          create_sprocs
        rescue
          @db = nil
          raise Poefy::StructureInvalid
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

    # Creates a database with the correct format.
    #   Convert input lines array to SQL import format file.
    #   Delete database if already exists.
    #   Create database using SQL import file.
    #   Delete both files.
    def make_new lines, description = nil
      make_new!(lines, description) unless exist?
    end

    # Force new database, overwriting existing.
    def make_new! lines, description = nil

      # Create a new database.
      new_connection

      # Create the lines table and the index.
      create_table table, description

      # Convert the lines array into an expanded array of rhyme metadata.
      import_data = lines_rhyme_metadata lines

      # Import the data.
      insert_lines table, import_data

      # Recreate the stored procedures.
      create_sprocs
    end

    # Public interfaces for private stored procedure methods.
    # Use instance variables to keep a cache of the results.
    def rhymes_by_count rhyme_count, syllable_min_max = nil
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
    def lines_by_rhyme rhyme, syllable_min_max = nil
      db
      @la = Hash.new { |h,k| h[k] = {} } if @la.nil?
      if @la[rhyme][syllable_min_max].nil?
        @la[rhyme][syllable_min_max] = if syllable_min_max
          sproc_lines_by_rhyme_syllables(rhyme, syllable_min_max)
        else
          sproc_lines_by_rhyme(rhyme)
        end
      end
      @la[rhyme][syllable_min_max].dup
    end

    private

      ##########################################################################

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

  end

end

################################################################################
