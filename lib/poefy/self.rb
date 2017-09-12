#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Class methods for Poefy module.
################################################################################

module Poefy

  # Array of all '.db' files in /data/.
  # Do not include databases used for testing.
  def self.all_databases
    path = File.expand_path('../../../data', __FILE__)
    Dir["#{path}/*.db"].map do |i|
      File.basename(i, '.db')
    end.reject do |i|
      i.start_with?('spec_')
    end - ['test']
  end

end

################################################################################
