#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Base internals for the PoefyGen class.
################################################################################

module Poefy

  module PoefyGenBase

    attr_reader :console, :db, :local, :overwrite

    def initialize db_name, options = {}
      handle_options options
      @db = Poefy::Database.new get_database_file(db_name), @console
    end

    # Make a database using the given lines.
    def make_database input, overwrite = @overwrite
      @db.close if @db
      if overwrite
        @db.make_new! validate_lines input
      else
        @db.make_new validate_lines input
      end
    end
    def make_database! input
      make_database input, true
    end

    # Close the database.
    def close
      @db.close
    end

    # Validate the lines. Arg could be a filename,
    #   newline delimited string, or array of lines.
    def validate_lines input

      # If the input is a file, then read it.
      lines = File.exists?(input) ? File.read(input) : input

      # If lines is not an array, assume string and split on newlines.
      lines = lines.respond_to?(:each) ? lines : lines.split("\n")
      lines.map(&:strip!)
      lines
    end

    private

      # Find the correct database file.
      # If local, just use the value.
      # Else, use the database in /data/ directory.
      def get_database_file database_name
        if @local
          database_name
        else
          path = File.expand_path('../../../data', __FILE__)
          file = File.basename(database_name, '.db')
          path + '/' + file + '.db'
        end
      end

      # Handle the optional initialize options hash.
      def handle_options options
        @console     = options[:console]   || false
        @overwrite   = options[:overwrite] || false
        @local       = options[:local]     || false
        @poetic_form = {}
        @poetic_form[:proper] = options[:proper] || true
        @poetic_form = validate_poetic_form options
      end

      # Make sure the options hash is in order.
      def validate_poetic_form poetic_form
        input, output = poetic_form, {}
        form_string   = get_valid_form input[:form]

        # Handle obvious inputs.
        output[:form]     = form_string      if form_string
        output[:rhyme]    = input[:rhyme]    if input[:rhyme]
        output[:indent]   = input[:indent]   if input[:indent]
        output[:syllable] = input[:syllable] if input[:syllable]
        output[:regex]    = input[:regex]    if input[:regex]
        output[:acrostic] = input[:acrostic] if input[:acrostic]

        # Tokenise string to arrays and hashes.
        rhyme = get_poetic_form_rhyme(output)
        if output[:rhyme]
          output[:rhyme] = tokenise_rhyme output[:rhyme]
        end
        if output[:syllable]
          output[:syllable] = transform_string_syllable output[:syllable], rhyme
        end
        if output[:regex]
          output[:regex] = transform_string_regex output[:regex], rhyme
        end

        # Get from instance by default.
        output[:proper] = input[:proper].nil? ?
                            @poetic_form[:proper] : input[:proper]

        # Tiny amendment to solve later errors.
        output[:rhyme] = ' ' if output[:rhyme] == ''
        output
      end

      # Handle error message. Quit the program if called from console.
      def handle_error msg
        if @console
          STDERR.puts msg
          exit 1
        end
        nil
      end

  end

end

################################################################################
