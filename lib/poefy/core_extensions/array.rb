#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Monkey patch the Array class.
################################################################################

#--
# Declare module structure.
#++
module Poefy
  module CoreExtensions
    module Array
      module SortByDistance
      end
      module ModuloIndex
      end
    end
  end
end

#--
# Define module methods.
#++
module Poefy::CoreExtensions::Array::SortByDistance

  ##
  # Take an array index and return a permutation of the
  # items sorted by distance from that index.
  # If 'index' is not specified, return an Enumerator
  # of the results for all indices, in order.
  #
  # The ':reverse' keyword argument switches the equally close
  # neighbours from lowest index first to highest first.
  # It's an option added mostly for completeness, but it's
  # there if you need it.
  #
  def sort_by_distance_from_index index = nil, reverse: false

    # Return Enumerator of all possible output arrays.
    if index.nil?
      Enumerator.new(self.count) do |y|
        self.each.with_index do |value, index|
          y << self.sort_by_distance_from_index(index, reverse: reverse)
        end
      end

    # Return Enumerator of results for a single index.
    else
      Enumerator.new(self.count) do |y|
        y << self[index]
        counter = 0
        loop do
          counter += 1

          # Consider negative indices OOB, not from array tail.
          below_index = index - counter
          below_index = nil if below_index < 0
          below = self[below_index] if below_index

          # This is fine, uses nil as default value if OOB.
          above = self[index + counter]

          # Both the elements with index one higher and one lower
          # are equally close neighbours to the subject element.
          # The default is to output the element with the lowest
          # index first. With ':reverse' set to true, the highest
          # index is appended first.
          if reverse
            y << above if above
            y << below if below
          else
            y << below if below
            y << above if above
          end

          # Break if we're at the last element.
          break if !above and !below
        end
      end
    end
  end

  ##
  # Find all elements that match 'value' and return the
  # sort_by_distance results for all, as an Enumerator.
  #
  def sort_by_distance_from_value value = nil, reverse: false
    matching = self.each_index.select { |i| self[i] == value }
    Enumerator.new(matching.count) do |y|
      matching.each do |index|
        y << self.sort_by_distance_from_index(index, reverse: reverse)
      end
    end
  end
end

#--
# Define module methods.
#++
module Poefy::CoreExtensions::Array::ModuloIndex

  ##
  # Return elements located at specific index periods.
  #
  def modulo_index(divider, remainder = 0, start_index = 0)
    self.values_at(* self.each_index.select do |i|
      (i + start_index) % divider == remainder
    end)
  end
end

#--
# Extend Array class.
#++
class Array
  include Poefy::CoreExtensions::Array::SortByDistance
  include Poefy::CoreExtensions::Array::ModuloIndex
end

################################################################################
