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

  # Array of all names of poetic forms.
  def self.all_poetic_forms
    PoeticForms::POETIC_FORMS.keys.reject { |i| i == :default }
  end

  # Find the root of the directory tree.
  def self.root
    File.expand_path('../../../', __FILE__)
  end

end

################################################################################
