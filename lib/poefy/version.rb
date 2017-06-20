#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# The current version number and date.
################################################################################

module Poefy

  def self.version_number
    Gem::Version.new VERSION::STRING
  end

  def self.version_date
    '2017-06-19'
  end

  module VERSION
    MAJOR = 0
    MINOR = 6
    TINY  = 1
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end

end

################################################################################
