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

    # Exit and send error to the console if no file loaded.
    rescue LoadError
      if loaded_file.nil?
        msg = "ERROR: Please specify the type of database to use." +
            "\n       The 'poefy' gem does not implement a database interface" +
            "\n       by default; you must install one of the below gems:" +
            "\n         gem install poefy-sqlite3" +
            "\n         gem install poefy-pg"
        if Poefy.console
          STDERR.puts msg
          exit 1
        end
        raise msg
      end
    end
  end

end

################################################################################
