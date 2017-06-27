#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Code for interfacing with the 'conditional_sample' gem.
################################################################################

module Poefy

  module ConditionalSample

    # Delete the first matching value in an array.
    def delete_first array, value
      array.delete_at(array.index(value) || array.length)
    end

    # Make sure each line ends with a different word.
    # This is intented to be used in 'conditions' procs.
    def diff_end arr, elem
      !arr.map{ |i| i['final_word'] }.include?(elem['final_word'])
    end

    # See if a line matches to a particular 'poetic_form'
    def validate_line line, poetic_form
      valid = true
      if poetic_form[:syllable] and poetic_form[:syllable] != 0
        valid = valid && [*poetic_form[:syllable]].include?(line['syllables'])
      end
      if poetic_form[:regex]
        [*poetic_form[:regex]].each do |i|
          valid = valid && !!(line['line'].match(i))
        end
      end
      valid
    end

    # Input a rhyme array and a poetic_form hash.
    # Create a line by line array of conditions.
    # This will be used to analyse the validity of corpus lines.
    def conditions_by_line tokenised_rhyme, poetic_form
      output = []
      tokenised_rhyme.each.with_index do |rhyme, index|
        line_hash = {
          line: index + 1,
          rhyme: rhyme[:token],
          rhyme_letter: rhyme[:rhyme_letter]
        }
        if rhyme[:refrain] and rhyme[:refrain] != ' '
          line_hash[:refrain] = rhyme[:refrain]
        end
        line_hash[:exact] = rhyme[:exact] if rhyme[:exact]
        poetic_form.keys.each do |k|
          if poetic_form[k].is_a? Hash
            line_hash[k] = poetic_form[k][index + 1]
          end
        end
        output << line_hash
      end
      output
    end

    # Group by element, with count as value. Ignore spaces.
    # e.g. {"A1"=>4, "b"=>6, "A2"=>4, "a"=>5}
    #  =>  {"b"=>6, "a"=>7}
    def unique_rhymes tokenised_rhyme

      # Group by element, with count as value. Ignore spaces.
      # e.g. {"A1"=>4, "b"=>6, "A2"=>4, "a"=>5}
      tokens = tokenised_rhyme.reject { |i| i == ' ' }
      grouped = tokens.each_with_object(Hash.new(0)) { |k,h| h[k] += 1 }

      # For each uppercase token, add one to the corresponding lowercase.
      uppers = grouped.keys.select{ |i| /[[:upper:]]/.match(i) }
      uppers.each { |i| grouped[i[0].downcase] += 1 }

      # Delete from the grouped hash if uppercase.
      grouped.delete_if { |k,v| /[[:upper:]]/.match(k) }
      grouped
    end

  end

end

################################################################################
