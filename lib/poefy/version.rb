#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# The current version number and date.
################################################################################

module Poefy

  def self.version_number
    major = 2
    minor = 0
    tiny  = 1
    pre   = nil

    string = [major, minor, tiny, pre].compact.join('.')
    Gem::Version.new string
  end

  def self.version_date
    '2025-06-28'
  end

end

################################################################################
