#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Poefy exception hierarchy.
# These errors have short messages for developers using the gem, and longer
#   messages for end users who will be using the bin through the console.
# If accessing through a console, all these errors are cause to exit.
################################################################################

module Poefy

  class Error < StandardError
    def console_msg
      "ERROR: " + msg
    end
    def initialize short_message, console_message = nil
      super short_message
    end
  end

  ##############################################################################

  class InputError < Error
  end

  class MissingFormOrRhyme < InputError
    def msg
      "No valid rhyme or form option specified"
    end
    def console_msg
        "ERROR: No valid rhyme or form option specified." +
      "\n       Try again using the -f or -r option." +
      "\n       Use -h or --help to view valid forms."
    end
    def initialize
      super msg, console_msg
    end
  end

  class RhymeError < InputError
    def msg
      "Rhyme string is not valid"
    end
    def initialize
      super msg
    end
  end

  class SyllableError < InputError
    def msg
      "Syllable string is not valid"
    end
    def initialize
      super msg
    end
  end

  class HashError < InputError
    def msg
      "Hash is not valid"
    end
    def initialize short_message = msg
      super short_message
    end
  end

  ##############################################################################

  class GenerationError < Error
  end

  class NotEnoughData < GenerationError
    def msg
      "Not enough rhyming lines in the input"
    end
    def initialize console_message = nil
      super msg, console_message
    end
  end

  ##############################################################################

  class DatabaseError < Error
  end

  class MissingDatabase < DatabaseError
    def msg
      "Database does not exist"
    end
    def initialize
      super msg
    end
  end

  class StructureInvalid < DatabaseError
    def msg
      "Database contains invalid structure"
    end
    def initialize console_message = nil
      super msg, console_message
    end
  end

  class MissingDBInterface < DatabaseError
    def msg
      "Database interface not specified"
    end
    def console_msg
        "ERROR: Please specify the type of database to use." +
      "\n       poefy does not implement a database interface by" +
      "\n       default; you must install one of the below gems:" +
      "\n         gem install poefy-sqlite3" +
      "\n         gem install poefy-pg"
    end
    def initialize
      super msg, console_msg
    end
  end

end

################################################################################
