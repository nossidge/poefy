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
    '2017-05-17'
  end

  module VERSION
    MAJOR = 0
    MINOR = 5
    TINY  = 0
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end

end

################################################################################
