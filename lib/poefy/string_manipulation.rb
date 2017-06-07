#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# A bunch of string manipulation.
################################################################################

require 'ruby_rhymes'
require 'wordfilter'
require 'humanize'

################################################################################

module Poefy

  module StringManipulation

    private

      # True if the whole text string can be expressed as Float.
      def numeric? text
        Float(text) != nil rescue false
      end

      # The first word in a text string. Relies on space for whitespace.
      # Discards any punctuation.
      def first_word text
        (text.gsub(/[[:punct:]]/,'').scan(/^[^ ]+/).first rescue '') || ''
      end

      # Uses 'ruby_rhymes' to find the rhyme key for a text.
      def get_rhymes text
        (numeric?(text[-1]) ? [] : text.to_phrase.rhymes.keys) rescue []
      end

      # The number of syllables in the text.
      def syllables text
        text.to_phrase.syllables rescue 0
      end

      # Final line must close with sentence-end punctuation.
      def end_the_sentence text
        if find = text.scan(/[[:punct:]]+$/).first
          swap = find.tr(',:;-', '.').delete('—–-')
          text.reverse.sub(find.reverse, swap.reverse).reverse
        else
          text += '.'
        end
      end

      # Does the sentence end with a .!?
      def has_stop_punctuation? text
        return false if text.nil?
        punct = text.scan(/[[:punct:]]+$/).first
        !!(punct.match(/[\.!?]/) if punct)
      end

      # Capitalise the first character of a string
      def capitalize_first text
        text[0] = text[0].upcase
        text
      end

      # Convert each element in an input array to Integer, and raise
      #   an error if the conversion is not possible for any element.
      def each_to_int input_array, error_to_raise = TypeError
        output_array = []
        input_array.each do |elem|
          begin
            output_array << Integer(elem)
          rescue ArgumentError => e
            raise error_to_raise
          end
        end
        output_array
      end

      # Combine two hashes together, transforming all values to array.
      # These arrays are then flattened.
      def merge_hashes one, two
        one ||= {}
        two ||= {}
        new_hash = Hash.new { |h,k| h[k] = [] }
        keys = (one.keys + two.keys).sort.uniq
        keys.each do |key|
          new_hash[key] << one[key] if one[key]
          new_hash[key] << two[key] if two[key]
          new_hash[key].flatten!
        end
        new_hash
      end

      # Fill a hash with a single value.
      # Keys are integers in a range.
      def fill_hash value, key_range
        output = {}
        key_range.each do |i|
          output[i] = value
        end
        output
      end

      # Is the string enclosed in brackets?
      def bracketed? string
        square = (string[0] == '[' and string[-1] == ']')
        curly  = (string[0] == '{' and string[-1] == '}')
        square or curly
      end

      # Humanize every number in the text.
      # This will not work for floats.
      # It will also break emoticons, but GIGO.
      def humanize_instr text
        output = text
        loop do
          num = output[/\d+/]
          break if not num
          output.sub!(num, num.to_i.humanize)
        end
        output
      end

  end

end

################################################################################
