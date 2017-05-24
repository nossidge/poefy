#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Description of various poetic forms.
# Also holds methods for parsing the form strings.
#
# All of this is better explained in the README.
#
### Rhyme strings:
# This is the most important argument.
#   All other form strings are based on this.
# Each token represents a line.
#   (Token examples: 'a', 'b', 'A1', ' ')
# Letters indicate rhymes, so all 'a' or 'A' lines have the same rhyme.
#   (Example, limerick: 'aabba')
# Uppercase letter lines will be duplicated exactly.
#   This is used to create refrain lines.
#   (Example, rondeau: 'aabba aabR aabbaR')
# Numbers after a capital letter indicate which specific line to repeat.
#   Letters indicate the same rhyme, uppercase or down.
#   (Example, villanelle: 'A1bA2 abA1 abA2 abA1 abA2 abA1A2'
#
### Indent strings:
# Each character represents a line.
# The numbers show how many times to repeat '  ' before each line.
# Any character that doesn't map to an integer defaults to 0.
# So '0011000101' and '0011 001 1' are the same.
#
### Syllable strings:
# '10'
# '9,10,11'
# '[8,8,5,5,8]'
# '[[8,9],[8,9],[4,5,6],[4,5,6],[8,9]]'
# '{1:8,2:8,3:5,4:5,5:8}'
# '{1:[8,9],2:[8,9],3:[4,5,6],4:[4,5,6],5:[8,9]}'
# '{0:[8,9],3:[4,5,6],4:[4,5,6]}'
# '{1:8,5:8}'
# '{1:8,2:8,3:5,-2:5,-1:8}'
#
### Regex strings:
# '^[A-Z].*$'
# '^[^e]*$'
# '{1=>/^[A-Z].*$/}'
#
################################################################################

module Poefy

  module PoeticForms

    # If the token is an array, then a random sample will be used.
    POETIC_FORMS = {
      default: {
        rhyme:    'a',
        indent:   '0',
        syllable: ''
      },
      rondeau: {
        rhyme:    'aabba aabR aabbaR',
        indent:   '',
        syllable: ''
      },
      villanelle: {
        rhyme:    'A1bA2 abA1 abA2 abA1 abA2 abA1A2',
        indent:   '010 001 001 001 001 0011',
        syllable: ''
      },
      ballade: {
        rhyme:    'ababbcbC ababbcbC ababbcbC bcbC',
        indent:   '',
        syllable: ''
      },
      ballata: {
        rhyme:    ['AbbaA','AbbaAbbaA','AbbaAbbaAbbaA'],
        indent:   '',
        syllable: ''
      },
      sonnet: {
        rhyme:    'ababcdcdefefgg',
        indent:   '',
        syllable: ''
      },
      petrarchan: {
        rhyme:    ['abbaabbacdecde','abbaabbacdccdc',
                   'abbaabbacddcdd','abbaabbacddece','abbaabbacdcdcd'],
        indent:   ['01100110010010','10001000100100'],
        syllable: ''
      },
      limerick: {
        rhyme:    'aabba',
        indent:   '',
        syllable: '{1:[8],2:[8],3:[4,5],4:[4,5],5:[8]}'
      },
      haiku: {
        rhyme:    'abc',
        indent:   '',
        syllable: '[5,7,5]'
      },
      common: {
        rhyme:    'abcb',
        indent:   '0101',
        syllable: '[8,6,8,6]'
      },
      ballad: {
        rhyme:    'abab',
        indent:   '0101',
        syllable: '[8,6,8,6]'
      },
      double_dactyl: {
        rhyme:    'abcd efgd',
        indent:   '',
        syllable: '[6,6,6,4,0,6,6,6,4]',
        regex:    '{7=>/^\S+$/}'
      }
    }

    # Create a regex specification for acrostics.
    #   acrostic('unintelligible')
    #   acrostic('unin tell igib le')
    def acrostic word
      output = {}
      counter = 1
      word.split('').each do |i|
        output[counter] = /^[#{i.upcase}#{i.downcase}]/ if i != ' '
        counter += 1
      end
      output
    end

    private

      # Can the string be converted to integer?
      def is_int? str
        !(Integer(str) rescue nil).nil?
      end

      # Make sure the form name is in the list.
      def get_valid_form form_name
        return nil if form_name.nil?
        POETIC_FORMS[form_name.to_sym] ? form_name.to_sym : nil
      end

      # Get full form, from either the user-specified options,
      #   or the default poetic form.
      def poetic_form_full poetic_form = @poetic_form
        rhyme     = get_poetic_form_token :rhyme,     poetic_form
        indent    = get_poetic_form_token :indent,    poetic_form
        syllable  = get_poetic_form_token :syllable,  poetic_form
        regex     = get_poetic_form_token :regex,     poetic_form
        transform = get_poetic_form_token :transform, poetic_form
        poetic_form[:rhyme]     = rhyme
        poetic_form[:indent]    = indent    if indent    != ''
        poetic_form[:syllable]  = syllable  if syllable  != ''
        poetic_form[:regex]     = regex     if regex
        poetic_form[:transform] = transform if transform != ' '
        poetic_form
      end

      # If the token is specified in the hash, return it,
      #   else get the token for the named form.
      def get_poetic_form_rhyme poetic_form = @poetic_form
        get_poetic_form_token :rhyme, poetic_form
      end
      def get_poetic_form_indent poetic_form = @poetic_form
        get_poetic_form_token :indent, poetic_form
      end
      def get_poetic_form_token token, poetic_form = @poetic_form
        if poetic_form.empty?
          ' '
        elsif poetic_form[token]
          poetic_form[token]
        elsif poetic_form[:form].nil?
          ' '
        elsif POETIC_FORMS[poetic_form[:form].to_sym].nil?
          ' '
        else
          token = POETIC_FORMS[poetic_form[:form].to_sym][token]
          token = token.is_a?(Array) ? token.sample : token
        end
      end

      # Turn a rhyme format string into a usable array of tokens.
      # Example formats:
      #   sonnet_form     = 'abab cdcd efef gg'
      #   villanelle_form = 'A1bA2 abA1 abA2 abA1 abA2 abA1A2'
      def tokenise_rhyme rhyme_string
        return rhyme_string if rhyme_string.is_a? Array

        tokens = []
        buffer = ''
        rhyme_string.split('').each do |char|
          if !numeric?(char) and buffer != ''
            tokens << buffer
            buffer = ''
          end
          buffer += char
        end
        tokens << buffer

        # Handle invalid tokens.
        # ["a1"] ["1"] ["1122"] [" 1"] [" 11"] [":1"]
        boolean_array = tokens.map do |i|
          keep = i.gsub(/[^A-Z,0-9]/,'')
          (keep == '' or !is_int?(keep) or !is_int?(keep))
        end
        valid = boolean_array.reduce{ |sum, i| sum && i }
        if !valid
          return handle_error 'ERROR: Rhyme string is not valid', []
        end
        tokens = [' '] if tokens == ['']
        tokens
      end

      # Indent an array of lines using a string of numbers.
      def do_indent lines, str
        return lines if str.nil? or lines.nil? or lines.empty?

        # Convert the indent string into an array.
        indent_arr = (str + '0' * lines.length).split('')
        indent_arr = indent_arr.each_slice(lines.length).to_a[0]

        # Convert to integers. Spaces should be zero.
        indent_arr.map! { |i| Integer(i) rescue 0 }

        # Zip, iterate, and prepend indent.
        indent_arr.zip(lines).map do |line|
          '  ' * line[0] + (line[1] ? line[1] : '')
        end
      end

      # Runs a block of code without warnings.
      # Used for 'eval' calls.
      def silence_warnings &block
        warn_level = $VERBOSE
        $VERBOSE = nil
        result = block.call
        $VERBOSE = warn_level
        result
      end

      # Sort by keys, to make it more human-readable.
      def sort_hash input
        output = {}
        input.keys.sort.each do |k|
          output[k] = input[k]
        end
        output
      end

      # '10'
      # '9,10,11'
      # '[8,8,5,5,8]'
      # '[[8,9],[8,9],[4,5,6],[4,5,6],[8,9]]'
      # '{1:8,2:8,3:5,4:5,5:8}'
      # '{1:[8,9],2:[8,9],3:[4,5,6],4:[4,5,6],5:[8,9]}'
      # '{0:[8,9],3:[4,5,6],4:[4,5,6]}'
      # '{1:8,5:8}'
      # '{1:8,2:8,3:5,-2:5,-1:8}'
      # Uses #eval, so pretty likely to mess up big time on error.
      # Use the rhyme string as base for the number of lines in total.
      def transform_string_syllable input, rhyme
        return input if input.is_a? Hash
        input = input.to_s
        transform_string_to_hash :syllable, input.gsub(':','=>'), rhyme, 0
      end

      # Do the same for regular expression strings.
      def transform_string_regex input, rhyme
        transform_string_to_hash :regex, input, rhyme, nil
      end

      # This should work for both syllable and regex strings.
      def transform_string_to_hash type, string, rhyme, default
        return string if string.is_a? Hash
        return {} if string == ' '

        output = {}
        line_count = tokenise_rhyme(rhyme).length

        # Figure out datatype.
        datatype = 'string'
        datatype = 'array' if !string.is_a?(Regexp) and string[0] == '['
        datatype = 'hash'  if !string.is_a?(Regexp) and string[0] == '{'

        # Convert string to array, and eval the others.
        if datatype == 'string'

          # Regex cannot be an array, but syllable can.
          if type == :syllable
            arr = each_to_int(string.split(','))
          elsif type == :regex
            arr = [Regexp.new(string)]
          end

          # Set this to be the default '0' hash value.
          arr = arr.first if arr.count == 1
          output = { 0 => arr }
          datatype = 'hash'
        else
          output = silence_warnings { eval string }
        end

        # Convert array to positioned hash.
        if datatype == 'array'
          output = output.map.with_index do |e, i|
            [i+1, e]
          end.to_h
        end

        # Go through each line and make sure there is a value for each.
        # Use default if there is no specific value.
        default_value = output[0] ? output[0] : default
        (1..line_count).each do |i|
          output[i] = default_value if output[i].nil?
        end

        # Handle negative keys.
        output.keys.each do |k|
          if k < 0
            line = line_count + 1 + k
            output[line] = output[k]
          end
        end

        # Remove keys less than or equal to zero.
        output.reject!{ |k| k <= 0 }

        # Return sorted hash.
        # ToDo: Doesn't need to be sorted in final code.
        sort_hash output
      end

  end

end

################################################################################
