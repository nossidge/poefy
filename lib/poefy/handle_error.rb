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
        if @console
          STDERR.puts msg
          exit 1
        end
        return_value
      end

      def raise_error msg
        if @console
          STDERR.puts msg
          exit 1
        end
        raise msg
      end

  end

end

################################################################################
