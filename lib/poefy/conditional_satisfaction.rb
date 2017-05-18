#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Two methods for assessing permutations of an input array versus an
#   array of conditions for each element.
# Both methods return an output array consisting of samples from an
#   input array, for which output[0] satisfies condition[0], etc.
# Both methods may take a whole lot of time, depending on how lenient the
#   conditions are. It is better for the stricter conditions to be at the
#   start of the array, due to the way the code is written.
# If none of the conditions match, then it will run in factorial time,
#   which will get exponentially longer the more elements there are in the
#   input array.
# I would recommend wrapping inside a Timeout block to assuage this. If it
#   fails to resolve in, say, two seconds, then it's probably not possible
#   to fit the conditions to the lines:
#       begin
#         Timeout::timeout(2) do
#           output = conditional_selection(lines.shuffle, conditions)
#         end
#       rescue
#         output = []
#       end
################################################################################
# '#conditional_permutation' returns a complete permutation of an array.
# i.e. output length == array length
# Any elements in the array that are extra to the number of conditions will
# be assumed valid.
#   array = [1,2,3,4,5].shuffle
#   conditions = [
#     proc { |arr, elem| elem < 2},
#     proc { |arr, elem| elem > 2},
#     proc { |arr, elem| elem > 1}
#   ]
#   possible output = [1,3,4,5,2]
################################################################################
# '#conditional_selection' returns an array that satisfies only the conditions.
# i.e. output length == conditions length
#   array = [1,2,3,4,5].shuffle
#   conditions = [
#     proc { |arr, elem| elem < 2},
#     proc { |arr, elem| elem > 2},
#     proc { |arr, elem| elem > 1}
#   ]
#   possible output = [1,5,3]
################################################################################
# Condition array:
# Must contain boolean procs using args |arr, elem|
# 'arr'   is a reference to the current array that has been built up
#         through the recursion chain.
# 'elem'  is a reference to the current element.
################################################################################

module Poefy

  module ConditionalSatisfaction

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
        valid = valid && !!(line['line'].match(poetic_form[:regex]))
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
          rhyme: rhyme,
          rhyme_letter: rhyme[0].downcase
        }
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

    ############################################################################

    # Return a permutation of 'array' where each element validates to the
    #   same index in a 'conditions' array of procs that return Boolean.
    # Will not work on arrays that contain nil values.
    def conditional_permutation array, conditions,
                                current_iter = 0,
                                current_array = []
      output = []

      # Get the current conditional.
      cond = conditions[current_iter]

      # Loop through and return the first element that validates.
      valid = false
      array.each do |elem|

        # Test the condition. If we've run out of elements
        #   in the condition array, then allow any value.
        valid = cond ? cond.call(current_array, elem) : true
        if valid

          # Remove this element from the array, and recurse.
          remain = array.dup
          delete_first(remain, elem)

          # If the remaining array is empty, no need to recurse.
          new_val = nil
          if !remain.empty?
            new_val = conditional_permutation(remain, conditions,
                                              current_iter + 1,
                                              current_array + [elem])
          end

          # If we cannot use this value, because it breaks future conditions.
          if !remain.empty? && new_val.empty?
            valid = false
          else
            output << elem << new_val
          end
        end

        break if valid
      end

      output.flatten.compact
    end

    # Return values from 'array' where each element validates to the same
    #   index in a 'conditions' array of procs that return Boolean.
    # Return an array of conditions.length
    def conditional_selection array, conditions,
                              current_iter = 0,
                              current_array = []
      output = []

      # Get the current conditional.
      cond = conditions[current_iter]

      # Return nil if we have reached the end of the conditionals.
      return nil if cond.nil?

      # Loop through and return the first element that validates.
      valid = false
      array.each do |elem|

        # Test the condition. If we've run out of elements
        #   in the condition array, then allow any value.
        valid = cond.call(current_array, elem)
        if valid

          # Remove this element from the array, and recurse.
          remain = array.dup
          delete_first(remain, elem)

          # If the remaining array is empty, no need to recurse.
          new_val = conditional_selection(remain, conditions,
                                          current_iter + 1,
                                          current_array + [elem])

          # If we cannot use this value, because it breaks future conditions.
          if new_val and new_val.empty?
            valid = false
          else
            output << elem << new_val
          end
        end

        break if valid
      end

      output.flatten.compact
    end

  end

end

################################################################################
