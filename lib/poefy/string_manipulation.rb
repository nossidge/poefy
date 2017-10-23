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

      # Return info that is returned using 'ruby_rhymes' '#to_phrase'
      # But also account for numbers and initialisms.
      def phrase_info text
        input = humanize_instr text
        phrase = input.to_phrase rescue nil
        return { rhymes: [], syllables: 0, last_word: '' } if phrase.nil?
        last_word = phrase.last_word.downcase rescue ''
        rhy = phrase.rhymes.keys rescue []
        rhy = rhyme_initialism(input) if rhy.empty?
        syl = syllables_correct text rescue 0
        { rhymes: rhy, syllables: syl, last_word: last_word }
      end

      # Humanize every number in the text.
      # This will not work for floats.
      # It will also break emoticons, but GIGO.
      def humanize_instr text
        output = text.dup
        loop do
          num = output[/\d+/]
          break if not num
          output.sub!(num, num.to_i.humanize)
        end
        output
      end

      # We will only call this method if there are no dictionary rhymes.
      # If the last word is uppercase, then assume it's an initialism.
      # Get the last letter and rhyme that.
      # Else, return an empty array, as normal.
      def rhyme_initialism text
        output = []
        last_word = text.split.last
        if last_word and last_word == last_word.upcase
          letter = last_word.scan(/[A-Z]/).last
          output = letter.to_phrase.rhymes.keys rescue []
        end
        output
      end

      # Get the correct syllable count, even for initialisms.
      # e.g. "Flew in from Miami Beach BOAC"
      #      "I'm back in the U.S.S.R"
      def syllables_correct text
        syll_count = 0

        # This is similar to how 'ruby_rhymes' splits to word.
        # But that gem ignores case, which we need.
        text.gsub(/[^A-Z ']/i,'').split.each do |word|

          # If the word has no rhymes, and it is uppercase, then assume
          #   it's an initialism and count each letter's syllables.
          if word.to_phrase.rhyme_keys.empty? and word == word.upcase
            word.gsub(/[^A-Z]/,'').split('').each do |i|
              syll_count += i.to_phrase.syllables
            end
          else
            syll_count += word.to_phrase.syllables
          end
        end
        syll_count
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

  end

end

################################################################################
