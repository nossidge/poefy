#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Methods for selecting which database interface to use.
# And for including the correct gem, based on that choice.
################################################################################

require 'yaml'

################################################################################

module Poefy

  # Are we running this through the console? (Or as a Ruby library?)
  def self.console= bool
    @@console = !!bool
  end
  def self.console
    @@console ||= false
  end

  # View and amend the database type in the 'settings' file.
  def self.database_type= db_name
    settings_file = Poefy.root + '/settings.yml'
    File.open(settings_file, 'w') do |file|
      hsh = {'database' => db_name}
      file.write hsh.to_yaml
    end
  end
  def self.database_type create_file = true
    settings_file = Poefy.root + '/settings.yml'
    if not File.exists?(settings_file)
      return nil if !create_file
      Poefy.database_type = 'pg'
    end
    YAML::load_file(settings_file)['database']
  end

  # Requires the chosen database interface gem.
  def self.require_db db_interface_gem = nil
    begin
      require 'poefy/' + (db_interface_gem || Poefy.database_type)

    # Replace with custom exception.
    rescue LoadError
      raise Poefy::MissingDBInterface
    end
  end

end

################################################################################
