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
    def initialize short_message, console_message
      if Poefy.console
        STDERR.puts console_message
        exit 1
      end
      super short_message
    end
  end

  class InputError < Error
  end

  class MissingFormOrRhyme < InputError
    def initialize msg = "No valid rhyme or form option specified"
      super
    end
  end

  class RhymeError < InputError
    def initialize msg = "Rhyme string is not valid"
      super
    end
  end

  class HashError < InputError
    # "ERROR: #{type.capitalize} is not valid"
    # "ERROR: #{type.capitalize} #{v} at line #{k} is not valid"
    def initialize msg = "Hash is not valid"
      super
    end
  end

  class GenerationError < Error
  end

  class NotEnoughData < GenerationError
    def initialize msg = "Not enough rhyming lines in the input"
      super
    end
  end

  class DatabaseError < Error
  end

  class FileError < DatabaseError
    def initialize msg = "Database does not yet exist"
      super
    end
  end

  class StructureInvalid < DatabaseError
    def initialize msg = "Database contains invalid structure"
      super
    end
  end

  class MissingDBInterface < DatabaseError
    @@msg = "Database interface not specified"
    @@con = "ERROR: Please specify the type of database to use." +
          "\n       'poefy' does not implement a database interface" +
          "\n       by default; you must install one of the below gems:" +
          "\n         gem install poefy-sqlite3" +
          "\n         gem install poefy-pg"
    def initialize
      super @@msg, @@con
    end
  end

end

################################################################################
