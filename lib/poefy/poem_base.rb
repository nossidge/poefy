#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Base internals for the Poem class.
################################################################################

module Poefy

  module PoemBase

    attr_reader :console, :corpus, :local, :overwrite

    def initialize db_name, options = {}
      handle_options options
      @corpus = Poefy::Database.new db_name, @local, @console
    end

    # Make a database using the given lines.
    def make_database input, description = nil, overwrite = @overwrite
      lines = validate_lines input
      lines.map! do |line|
        line.force_encoding('utf-8')
            .gsub("\u00A0", ' ')
            .strip
      end
      @corpus.close if @corpus
      if overwrite
        @corpus.make_new! lines, description
      else
        @corpus.make_new lines, description
      end
    end
    def make_database! input, description = nil
      make_database input, description, true
    end

    # Close the database.
    def close
      @corpus.close
    end

    # Validate the lines. Arg could be a filename,
    #   newline delimited string, or array of lines.
    def validate_lines input

      # If the input is a file, then read it.
      lines = File.exists?(input.to_s) ? File.read(input) : input

      # If lines is not an array, assume string and split on newlines.
      lines.respond_to?(:each) ? lines : lines.split("\n")
    end

    private

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

        # Apply ':form_from_text' before any others.
        if input[:form_from_text]
          lines = validate_lines input[:form_from_text]
          form = poetic_form_from_text lines
          input = form.merge input
        end

        # Handle obvious inputs.
        output[:form]       = form_string        if form_string
        output[:rhyme]      = input[:rhyme]      if input[:rhyme]
        output[:indent]     = input[:indent]     if input[:indent]
        output[:syllable]   = input[:syllable]   if input[:syllable]
        output[:regex]      = input[:regex]      if input[:regex]
        output[:acrostic]   = input[:acrostic]   if input[:acrostic]
        output[:acrostic_x] = input[:acrostic_x] if input[:acrostic_x]
        output[:transform]  = input[:transform]  if input[:transform]

        # Tokenise string to arrays and hashes.
        if output[:rhyme]
          output[:rhyme] = tokenise_rhyme output[:rhyme]
        end
        rhyme = get_poetic_form_rhyme(output)
        if output[:syllable] and rhyme != ' '
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
