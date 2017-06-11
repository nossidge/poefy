#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Monkey patch the Array class.
################################################################################

# [array] is the same array as [self], but ordered by closeness to the index.
# Optionally pass an integer, for results for just that index element.
# Returns a hash, or an array of hashes, in the form:
#   { :index => original index,
#     :value => original element,
#     :array => self array minus value, ordered by closeness to index }
# Example usage:
#   lines = (1..4).to_a * 2
#   puts lines.by_closeness
#   puts lines.by_closeness(3)
module Poefy
  module CoreExtensions
    module Array
      def by_closeness index = nil
        if index.nil?
          self.map.with_index do |value, index|
            self.by_closeness index
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
          { index: index, value: self[index], array: others }
        end
      end
    end
  end
end

class Array
  include Poefy::CoreExtensions::Array
end

################################################################################
