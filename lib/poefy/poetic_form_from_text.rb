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
        hash[:strip] = line.strip
        hash[:downcase] = line.strip.gsub(/[[:punct:]]/, '').downcase
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
        hash[:strip] = line[:strip]
        hash[:downcase] = line[:downcase]

        # Get the phrase info for the line.
        phrase = phrase_info line[:strip]

        # Misc details.
        hash[:num] = index + 1
        hash[:syllable] = phrase[:syllables]
        hash[:last_word] = phrase[:last_word]
        hash[:indent] = (line[:orig].length - line[:orig].lstrip.length) / 2

        # The rhyme tag array for the line.
        hash[:rhyme_tags] = phrase[:rhymes]

        # Map [:refrain] and [:exact].
        # (They are mutually exclusive)
        # If it needs to be an exact line, we don't need rhyme tokens.
        if bracketed?(line[:strip])
          hash[:exact] = line[:strip]
          hash[:rhyme_letter] = nil
          hash[:syllable] = 0
        elsif refrains.keys.include?(line[:downcase])
          hash[:refrain] = refrains[line[:downcase]]
        end

        hash
      end

      # [:rhyme_tags] may well contain more than one rhyme tag.
      # e.g. 'wind' rhymes with 'sinned' and 'find'.
      # So we will compare this array against the rhymes of each
      #   other line in the array, to find the correct one to use.
      # We will work from the closest lines, until we find a match.
      lines.each.with_index do |line, index|

        # Compare each other rhyme tag, order by closeness.
        found_rhyme = line[:rhyme_tags].first
        if line[:rhyme_tags].length > 1
          lines.by_distance(index).each do |i|
            i[:rhyme_tags].each do |tag|
              if line[:rhyme_tags].include?(tag)
                found_rhyme = tag
                break
              end
            end
          end
        end

        # If we haven't found the rhyme, then it doesn't matter,
        #   just use the first in the tag array.
        lines[index][:rhyme_tags]   = *found_rhyme
        lines[index][:rhyme_tag]    =  found_rhyme
        lines[index][:rhyme_letter] =  found_rhyme
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

      # Has to be a single character, so 9 is the maximum.
      indent = lines.map do |line|
        line[:indent] >= 9 ? 9 : line[:indent]
      end.join

      poetic_form = {
        rhyme: rhyme,
        syllable: syllable,
        indent: indent
      }
      poetic_form
    end

  end

end

################################################################################
