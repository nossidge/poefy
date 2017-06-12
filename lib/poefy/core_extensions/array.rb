#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Monkey patch the Array class.
################################################################################

# [array] is the same array as [self], but ordered by closeness to the index.
# Optionally pass an integer, for results for just that index element.
# Returns a Struct, or an array of Structs, in the form:
#   .index => original index
#   .value => original element
#   .array => self array minus value, ordered by closeness to index
# Example usage:
#   lines = (1..4).to_a * 2
#   puts lines.by_distance
#   puts lines.by_distance(3)
#   lines.by_distance(3).each { ... }
module Poefy
  module CoreExtensions

    # Output struct for #by_distance method.
    # Array is the most useful data, but index and value are also kept.
    IndexValueArray = Struct.new(:index, :value, :array) do
      alias_method :to_a, :array
      include Enumerable
      def each &block
        array.each do |i|
          block.call i
        end
      end
    end

    module Array

      def by_distance index = nil
        if index.nil?
          self.map.with_index do |value, index|
            self.by_distance index
          end
        else
          others, counter = [], 0
          loop do
            counter += 1
            below_index = index - counter
            below_index = nil if below_index < 0
            below = self[below_index] if below_index
            above = self[index + counter]
            others << below if below
            others << above if above
            break if !above and !below
          end
          IndexValueArray.new(index, self[index], others)
        end
      end
    end
  end
end

class Array
  include Poefy::CoreExtensions::Array
end

################################################################################
