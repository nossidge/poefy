#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Methods for selecting which database interface to use.
# And for including the correct gem, based on that choice.
################################################################################

module Poefy

  # Are we running this through the console? (Or as a Ruby library?)
  def self.console= bool
    @@console = !!bool
  end
  def self.console
    @@console ||= false
  end

  # Attempt to load exactly one of the below files.
  # Array is ordered by priority, so use PostgreSQL before SQLite.
  # ToDo: Replace with 'poefy/pg' and 'poefy/sqlite3'
  def self.require_db type = ['pg', 'sqlite3']

    loaded_file = nil
    [*type].each do |file|
      begin
        require_relative file
        loaded_file = file
        break
      rescue LoadError
      end
    end

    # Exit and send error to the console if no file loaded.
    if loaded_file.nil?
      msg = "ERROR: Please specify the type of database to use." +
          "\n       The 'poefy' gem does not implement a database interface" +
          "\n       by default; you must install one of the below gems:" +
          "\n         gem install poefy-sqlite3" +
          "\n         gem install poefy-pg"
      STDERR.puts msg
      exit 1
    end

  end

end

################################################################################
