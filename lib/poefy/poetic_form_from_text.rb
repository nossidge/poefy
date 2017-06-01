#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Read a song lyric file, output a poetic_form that matches its form.
################################################################################

module Poefy

  module PoeticFormFromText

    # Read a song lyric file, output a poetic_form that matches its form.
    def poetic_form_from_text text_file
      lines = File.readlines(text_file).map(&:strip)

      # We don't care about the lines exactly, just the structure.
      # So we can delete punctuation and downcase.
      lines = lines.map { |i| i.gsub(/[[:punct:]]/, '').downcase }

      # Find all the lines that are duplicated.
      # These will be the refrain lines.
      refrains = lines.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
      refrains = refrains.select { |k, v| v > 1 && k != '' }.keys

      # Give each a unique refrain ID.
      buffer = {}
      refrains.each.with_index { |line, id| buffer[line] = id }
      refrains = buffer

      # Find the rhyme of each line, and add refrain ID if needed.
      # Output as an array of hashes.
      lines = lines.map.with_index do |text, index|

        # ToDo: For now, just get the first rhyme.
        #       [:rhyme_letter] will be the same.
        rhyme_tag = get_rhymes(text).first

        # Output hash for the line.
        hash = {
          line: index + 1,
          text: text,
          last_word: (text.to_phrase.last_word rescue ''),
          syllable: syllables(text),
          rhyme_tag: rhyme_tag || ' ',
          rhyme_letter: rhyme_tag
        }
        hash[:refrain] = refrains[text] if refrains.keys.include? text
        hash[:rhyme] = ' ' if text == ''
        hash
      end

      # Okay, so we now have a hash that is equivalent to 'by_line'
      #   in '#gen_poem_using_conditions'
      # So that's it, we're good to go!
      # Actually, no. We need to split this up further into ':rhyme_letter',
      #   ':refrain', and ':syllable'.
      # This seems a bit perverse, as we'll be reassembling them back later,
      #   but it's the only way to be able to further alter the options.

      rhyme = lines.map do |line|
        hash = {}
        hash[:token] = line[:rhyme_letter] || ' '
        hash[:rhyme_letter] = hash[:token]
        hash[:refrain] = line[:refrain] if line[:refrain]
        hash
      end

      syllable = {}
      lines.map.with_index do |line, index|
        syllable[index+1] = line[:syllable] # if line[:syllable] > 0
      end

      poetic_form = {
        rhyme: rhyme,
        syllable: syllable
      }
      poetic_form
    end

  end

end

################################################################################
