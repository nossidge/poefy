#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Read a song lyric file, output a poetic_form that matches its form.
################################################################################

module Poefy

  module PoeticFormFromText

    # Read a song lyric file, output a poetic_form that matches its form.
    def poetic_form_from_text lines

      # If lines is not an array, assume string and split on newlines.
      lines = lines.respond_to?(:each) ? lines : lines.split("\n")

      # Remove duplicate '' elements that are neighbours in the array.
      # https://genius.com/The-monkees-im-a-believer-lyrics
      prev_line = ''
      lines.map! do |i|
        out = (i == '' && prev_line == '') ? nil : i
        prev_line = i
        out
      end
      lines.compact!

      # For refrains, we don't care about the lines exactly, just
      #   the structure. So we can delete punctuation and downcase.
      lines = lines.map do |line|
        hash = {}
        hash[:orig] = line
        hash[:downcase] = line.gsub(/[[:punct:]]/, '').downcase
        hash
      end

      # Find all the lines that are duplicated.
      # These will be the refrain lines.
      refrains = lines.map { |i| i[:downcase] }
      refrains = refrains.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
      refrains = refrains.select { |k, v| v > 1 && k != '' }.keys

      # Give each a unique refrain ID.
      buffer = {}
      refrains.each.with_index { |line, id| buffer[line] = id }
      refrains = buffer

      # Loop through and describe each line.
      lines = lines.map.with_index do |line, index|
        hash = {}

        # Text of the line.
        hash[:orig] = line[:orig]
        hash[:downcase] = line[:downcase]

        # Get the phrase info for the line.
        phrase = phrase_info line[:orig]

        # Misc details.
        hash[:num] = index + 1
        hash[:syllable] = phrase[:syllables]
        hash[:last_word] = phrase[:last_word]

        # The rhyme for the line.
        # ToDo: For now, just get the first rhyme of the tag array.
        rhyme_tag = phrase[:rhymes].first
        hash[:rhyme_tag] = rhyme_tag || ' '
        hash[:rhyme_letter] = rhyme_tag
        hash[:rhyme] = ' ' if hash[:downcase] == ''

        # Map [:refrain] and [:exact].
        # (They are mutually exclusive)
        # If it needs to be an exact line, we don't need rhyme tokens.
        if bracketed?(line[:orig].strip)
          hash[:exact] = line[:orig]
          hash[:rhyme] = ' '
          hash[:rhyme_letter] = nil
          hash[:syllable] = 0
        elsif refrains.keys.include?(line[:downcase])
          hash[:refrain] = refrains[line[:downcase]]
        end

        hash
      end

      # Split into separate sections, [:rhyme] and [:syllable].
      rhyme = lines.map do |line|
        hash = {}
        hash[:token] = line[:rhyme_letter] || ' '
        hash[:rhyme_letter] = hash[:token]
        hash[:refrain] = line[:refrain] if line[:refrain]
        hash[:exact] = line[:exact] if line[:exact]
        hash
      end

      syllable = {}
      lines.map.with_index do |line, index|
        syllable[index+1] = line[:syllable] if line[:syllable] > 0
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
