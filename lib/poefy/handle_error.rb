#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Handle error message.
# Quit the program if called from console.
################################################################################

module Poefy

  module HandleError

    private

      def handle_error msg, return_value = nil
        if Poefy.console
          STDERR.puts msg
          exit 1
        end
        return_value
      end

      def raise_error msg
        if Poefy.console
          STDERR.puts msg
          exit 1
        end
        raise msg
      end

  end

end

################################################################################

module Poefy

  # These errors have short messages for developers using the gem, and longer
  #   messages for end users who will be using the bin through the console.
  # If accessing through a console, all these errors are cause to exit.
  class Error < StandardError
    def initialize short_message, console_message = nil
      if Poefy.console
        console_message ||= "ERROR: " + short_message
        STDERR.puts console_message
        exit 1
      end
      super short_message
    end
  end

  class InputError < Error
  end

  class MissingFormOrRhyme < InputError
    @@msg = "No valid rhyme or form option specified"
    @@con = "ERROR: No valid rhyme or form option specified." +
          "\n       Try again using the -f or -r option." +
          "\n       Use -h or --help to view valid forms."
    def initialize
      super @@msg, @@con
    end
  end

  class RhymeError < InputError
    @@msg = "Rhyme string is not valid"
    def initialize
      super @@msg
    end
  end

  class HashError < InputError
    @@msg = "Hash is not valid"
    def initialize msg = @@msg
      super @@msg
    end
  end

  class GenerationError < Error
  end

  class NotEnoughData < GenerationError
    @@msg = "Not enough rhyming lines in the input"
    def initialize con = nil
      super @@msg, con
    end
  end

  class DatabaseError < Error
  end

  class MissingDatabase < DatabaseError
    @@msg = "Database does not yet exist"
    def initialize
      super @@msg
    end
  end

  class StructureInvalid < DatabaseError
    @@msg = "Database contains invalid structure"
    def initialize con = nil
      super @@msg, con
    end
  end

  class MissingDBInterface < DatabaseError
    @@msg = "Database interface not specified"
    @@con = "ERROR: Please specify the type of database to use." +
          "\n       poefy does not implement a database interface by" +
          "\n       default; you must install one of the below gems:" +
          "\n         gem install poefy-sqlite3" +
          "\n         gem install poefy-pg"
    def initialize
      super @@msg, @@con
    end
  end

end

################################################################################
