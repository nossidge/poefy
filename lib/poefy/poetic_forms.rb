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

require 'yaml'

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
        rhyme:    ['abbaabbacdecde','abbaabbacdccdc','abbaabbacdcddc',
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
        syllable: '{o:8,e:6}'
      },
      ballad: {
        rhyme:    'abab',
        indent:   '0101',
        syllable: '{o:8,e:6}'
      },
      double_dactyl: {
        rhyme:    'abcd efgd',
        indent:   '',
        syllable: '{0:6, 4m0:4}',
        regex:    '{7: ^\S+$}'
      }
    }

    # Create a regex specification for acrostics.
    #   acrostic('unintelligible')
    #   acrostic('unin tell igib le')
    def acrostic word
      output = {}
      word.split('').each.with_index do |char, i|
        output[i + 1] = /^[#{char.downcase}]/i if char != ' '
      end
      output
    end

    # Create a regex specification for acrostics.
    # Uses special logic for 'X'.
    # Match words starting 'ex' and then change case to 'eX'.
    def acrostic_x word
      regex = {}
      transform = {}
      word.split('').each.with_index do |char, i|
        if char.downcase == 'x'
          regex[i + 1] = /^ex/i
          transform[i + 1] = proc do |line|
            line[0..1] = 'eX'
            ' ' + line
          end
        elsif char != ' '
          regex[i + 1] = /^[#{char.downcase}]/i
          transform[i + 1] = proc do |line|
            '  ' + line
          end
        end
      end
      { regex: regex, transform: transform }
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
      def get_poetic_form_rhyme_longest poetic_form = @poetic_form
        get_poetic_form_token :rhyme, poetic_form, true
      end
      def get_poetic_form_rhyme poetic_form = @poetic_form
        get_poetic_form_token :rhyme, poetic_form
      end
      def get_poetic_form_indent poetic_form = @poetic_form
        get_poetic_form_token :indent, poetic_form
      end
      def get_poetic_form_token token,
                                poetic_form = @poetic_form,
                                longest = false
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
          if token.is_a?(Array)
            token = longest ? token.max_by(&:length) : token.sample
          end
          token
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
          (keep == '' or !is_int?(keep))
        end
        valid = boolean_array.reduce{ |sum, i| sum && i }
        raise Poefy::RhymeError unless valid
        tokens = [' '] if tokens == ['']

        # Output as a hash.
        tokens.map do |i|
          hash = {
            token: i,
            rhyme_letter: i[0].downcase
          }
          hash[:refrain] = i if i[0] == i[0].upcase
          hash
        end
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

      # Sort by keys, to make it more human-readable.
      def sort_hash input
        output = {}
        input.keys.sort.each do |k|
          output[k] = input[k]
        end
        output
      end

      # Convert a range in the string form "1-6" to an array.
      # Assumes elements are integers.
      def range_to_array input
        return input if input.is_a?(Numeric) || !input.include?('-')
        vals = input.split('-').map(&:to_i).sort
        (vals.first..vals.last).to_a
      end

      # Convert an array in the string form "4,6,8-10,12" to an array.
      # Assumes elements are positive integers.
      def string_to_array input
        return [input.to_i.abs] if input.is_a?(Numeric)
        arr = input.is_a?(Array) ? input : input.split(',')

        # Convert to positive integers, and remove duplicates.
        output = arr.map do |i|
          range_to_array(i)
        end.flatten.map do |i|
          i.to_i.abs
        end.sort.uniq.select do |i|
          i != 0
        end

        # This cannot be an empty array []. It will fail anyway when we
        #   come to do the poem generation, but it's better to fail now.
        raise Poefy::SyllableError.new if output.empty?
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
      # Use the rhyme string as base for the number of lines in total.
      def transform_input_syllable input, rhyme
        tokens = tokenise_rhyme rhyme
        hash = transform_input_to_hash :syllable, input
        hash = validate_hash_values :syllable, hash
        hash = expand_hash_keys :syllable, hash, tokens, 0
      end

      # Do the same for regular expression strings.
      def transform_input_regex input, rhyme
        tokens = tokenise_rhyme rhyme
        hash = transform_input_to_hash :regex, input
        hash = validate_hash_values :regex, hash
        hash = expand_hash_keys :regex, hash, tokens, //
      end

      # This should work for both syllable and regex strings.
      # It should also be fine for Integer and Regexp 'input' values.
      def transform_input_to_hash type, input
        return input if input.is_a? Hash

        # Don't go any further if we've got an invalid type.
        valid_non_string =
          input.is_a?(Array) ||
          (type == :syllable and input.is_a?(Numeric)) ||
          (type == :regex and input.is_a?(Regexp))
        valid_string_like = !valid_non_string && input.respond_to?(:to_s)
        raise TypeError unless valid_non_string || valid_string_like

        # Perform different tasks depending on type.
        input.strip! if input.is_a? String
        input = input.to_i if input.is_a? Numeric
        input = input.to_s if valid_string_like
        return {} if input == ''

        # This will be built up over the course of the method.
        output = {}

        # Figure out datatype.
        # Regex string input cannot be an array, but syllable can.
        datatype = :string
        if !input.is_a?(Regexp)
          if input.is_a?(Array)
            datatype = :array
          elsif type == :syllable and input[0] == '[' and input[-1] == ']'
            datatype = :array
          elsif input[0] == '{' and input[-1] == '}'
            datatype = :hash
          end
        end

        # If it's a basic string format, convert it to hash.
        if datatype == :string

          # Regex cannot be an array or range, but syllable can.
          if type == :regex
            arr = (input == []) ? [] : [Regexp.new(input)]

          # Special case for if a user explicitly states only '0'.
          elsif type == :syllable
            arr = input == '0' ? [0] : string_to_array(input)
          end

          # Set this to be the default '0' hash value.
          arr = arr.first if arr.count == 1
          output = { 0 => arr }
          datatype = :hash

        # If it's wrapped in [] or {}, then evaluate it using YAML.
        else

          # Don't need to evaluate if it's already an Array.
          if input.is_a?(Array)
            output = input
          else
            begin
              # If it's a regex, mandate the ': ' key separator.
              # (This is so the string substitutions don't mess up the regex.)
              # If it's a syllable, we can be more flexible with gsubs.
              as_yaml = input
              if type == :syllable
                as_yaml = input.gsub(':', ': ').gsub('=>', ': ')
              end
              output = YAML.load(as_yaml)
            rescue
              # Raise a SyllableError or RegexError.
              msg = "#{type.capitalize} hash is not valid YAML"
              e = Object.const_get("Poefy::#{type.capitalize}Error")
              raise e.new(msg)
            end
          end
        end

        # Convert array to positioned hash.
        if datatype == :array
          output = output.map.with_index do |e, i|
            [i+1, e]
          end.to_h
        end

        output
      end

      # Run different methods on each value depending on the type.
      # If it's a syllable, convert all values to int arrays.
      # If it's a regex, convert all values to regexp.
      def validate_hash_values type, input
        format_value = if type == :syllable
          Proc.new do |x|
            arr = string_to_array(x)
            arr.count == 1 ? arr.first : arr
          end
        elsif type == :regex
          Proc.new do |x|
            x.is_a?(Regexp) ? x : Regexp.new(x.to_s)
          end
        end

        # Validate values.
        if input.is_a?(Hash)
          input.each do |k, v|
            begin
              input[k] = format_value.call(v)
            rescue
              # Raise a SyllableError or RegexError.
              msg = "#{type.capitalize} hash invalid, key='#{k}' value='#{v}'"
              e = Object.const_get("Poefy::#{type.capitalize}Error")
              raise e.new(msg)
            end
          end
        elsif input.is_a?(Array)
          input.map! do |i|
            i = format_value.call(i)
          end
        end
        input
      end

      # Convert non-positive-integer keys into the correct position.
      def expand_hash_keys type, input, tokens, default
        output = input.dup
        line_count = tokens.length

        # Handle negative keys.
        output.keys.each do |k|
          if k.is_a?(Numeric) and k < 0
            line = line_count + 1 + k
            output[line] = output[k]
          end
        end

        # Find all lines that are not empty.
        content_lines = tokens.map.with_index do |v, i|
          i + 1 if (v[:token].strip != '')
        end.compact

        # Handle modulo lines.
        # Handle 'e' even and 'o' odd lines.
        modulo_lines = {}
        output.keys.each do |k|
          is_modulo = k.respond_to?(:include?) && k.include?('m')
          is_even_odd = %w[e o].include?(k)
          if is_modulo or is_even_odd
            if is_modulo
              vals = k.split('m').map(&:to_i)
              divider = vals.first.to_i.abs
              remainder = vals.last.to_i.abs
              if divider == 0
                # Raise a SyllableError or RegexError.
                msg = "#{type.capitalize} hash invalid,"
                msg += " key='#{k}', modulo='#{divider}m#{remainder}'"
                e = Object.const_get("Poefy::#{type.capitalize}Error")
                raise e.new(msg)
              end
            elsif is_even_odd
              divider = 2
              remainder = (k == 'e') ? 0 : 1
            end
            content_lines.modulo_index(divider, remainder, 1).each do |i|
              modulo_lines[i] = output[k]
            end
          end
        end

        # Take {modulo_lines} as the base and overwrite it with specified keys.
        if modulo_lines
          output.keys.each do |k|
            modulo_lines[k] = output[k]
          end
          output = modulo_lines
        end

        # Go through each line and make sure there is a value for each.
        # Use default if there is no specific value.
        default_value = output[0] ? output[0] : default
        (1..line_count).each do |i|
          output[i] = default_value if output[i].nil?
        end

        # Remove keys that are not numeric, or are less than or equal to zero.
        output.reject!{ |k| !k.is_a?(Numeric) or k <= 0 }

        # Return sorted hash.
        sort_hash output
      end

  end

end

################################################################################
