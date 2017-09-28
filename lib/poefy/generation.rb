#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Handle the procedural generation of poems.
################################################################################

require 'timeout'

################################################################################

module Poefy

  module Generation

    # Generate specific poem types.
    def poem poetic_form = @poetic_form

      if !@corpus.exists?
        return handle_error 'ERROR: Database does not yet exist', nil
      end

      # Validate the poetic form hash.
      raise ArgumentError, 'Argument must be a hash' unless
            poetic_form.is_a?(Hash)
      poetic_form = validate_poetic_form poetic_form
      poetic_form = @poetic_form.merge poetic_form

      # Make sure the hash contains ':form' or ':rhyme' keys.
      if !(poetic_form[:form] or poetic_form[:rhyme])
        return handle_error \
          "ERROR: No valid rhyme or form option specified.\n" +
          "       Try again using the -f or -r option.\n" +
          "       Use -h or --help to view valid forms."
      end

      # Loop until we find a valid poem.
      # There are cases where valid permutations are not able to be
      #   genned on the first try, so keep trying a few more times.
      output, count_down = nil, 10
      loop do
        output = gen_poem_using_conditions poetic_form
        break if !output.nil? || count_down == 0
        count_down -= 1
      end

      # Return nil if poem could not be created.
      return nil if (output.nil? or output == [] or output == [''])

      # Indent the output using the :indent string.
      output = do_indent(output, get_poetic_form_indent(poetic_form))

      # Append blank lines to the end if the :rhyme demands it.
      rhyme = tokenise_rhyme get_poetic_form_rhyme poetic_form
      (output.length...rhyme.length).each do |i|
        output[i] = ''
      end

      output
    end

    private

      # Use the constraints in 'poetic_form' to generate a poem.
      def gen_poem_using_conditions poetic_form = @poetic_form
        poetic_form = poetic_form_full poetic_form
        poetic_form = validate_poetic_form poetic_form

        # Tokenise the rhyme string, and return [] if invalid.
        tokenised_rhyme = tokenise_rhyme poetic_form[:rhyme]
        if tokenised_rhyme == []
          return handle_error 'ERROR: Rhyme string is not valid', []
        end

        # Expand poetic_form[:transform], if there's just one element.
        if poetic_form[:transform] and !poetic_form[:transform].respond_to?(:each)
          poetic_form[:transform] = fill_hash poetic_form[:transform],
                                              1..tokenised_rhyme.count
        end

        # Add acrostic to the regex, if necessary.
        if poetic_form[:acrostic_x]
          acrostic_opts = acrostic_x(poetic_form[:acrostic_x])
          poetic_form[:regex] =
            merge_hashes poetic_form[:regex], acrostic_opts[:regex]
          poetic_form[:transform] =
            merge_hashes acrostic_opts[:transform], poetic_form[:transform]
        elsif poetic_form[:acrostic]
          poetic_form[:regex] =
            merge_hashes poetic_form[:regex], acrostic(poetic_form[:acrostic])
        end

        # Add line number as ':line' in each element's hash.
        by_line = conditions_by_line(tokenised_rhyme, poetic_form)

        # If the poetic_form[:proper] option is true, we're going to
        #   need to add additional regex conditions to the first and
        #   last lines.
        # This is pretty easy for non-repeating lines, but for refrains
        #   we need to apply the regex for all occurrences.
        if poetic_form[:proper]

          # Turn the regex into an array, if it isn't already.
          # Then add the banned starting words.
          line_conds = [*by_line[0][:regex]]
          line_conds += [/^((?!and).)/i]
          line_conds += [/^((?!but).)/i]
          line_conds += [/^((?!or).)/i]
          line_conds += [/^((?!nor).)/i]
          line_conds += [/^((?!yet).)/i]
          by_line[0][:regex] = line_conds

          # Same for the last line.
          line_conds = [*by_line[tokenised_rhyme.count-1][:regex]]
          line_conds += [/[\.?!]$/]
          by_line[tokenised_rhyme.count-1][:regex] = line_conds

          # Get all refrains and group them.
          refrains = by_line.select do |i|
            i[:refrain]
          end.group_by do |i|
            i[:refrain]
          end

          # Now make each refrain :regex be an array of all.
          refrain_regex = Hash.new { |h,k| h[k] = [] }
          refrains.each do |key, value|
            refrain_regex[key] = value.map do |i|
              i[:regex]
            end.flatten.compact
          end

          # Go through [by_line] and update each :regex.
          by_line.each do |i|
            if not refrain_regex[i[:rhyme]].empty?
              i[:regex] = refrain_regex[i[:rhyme]]
            end
          end
        end

        # Now we have ':line', so we can break the array order.
        # Let's get rid of empty lines, and group by the rhyme letter.
        conditions_by_rhyme = by_line.reject do |i|
          i[:rhyme] == ' '
        end.group_by do |i|
          i[:rhyme_letter]
        end

        # Okay, this is great. But if we're making villanelles we'll need to
        #   duplicate refrain lines. So we won't need unique rhymes for those.
        # So make a distinct set of lines conditions, still grouped by rhyme.
        # This will be the same as [conditions_by_rhyme], except duplicate
        #   lines are removed. (In string input, these are lines with
        #   capitals and numbers: i.e. A1, B2)
        # It will keep the condition hash of only the first refrain line.
        distinct_line_conds = Hash.new { |h,k| h[k] = [] }
        conditions_by_rhyme.each do |key, values|
          refrains = []
          values.each do |v|
            if !v[:refrain]
              distinct_line_conds[key] << v
            elsif !refrains.include?(v[:refrain])
              refrains << v[:refrain]
              distinct_line_conds[key] << v
            end
          end
        end

        # Right, let's now loop through each rhyme group and find all from
        #   the database where the number of lines can be fulfilled.

        # First, get the order of rhymes, from most to least.
        distinct_line_conds = distinct_line_conds.sort_by{ |k,v| v.count }.reverse

        # This will store the rhymes that have already been used in the poem.
        # This is so we do not duplicate rhymes between distinct rhyme letters.
        rhymes_already_used = []

        # This is the final set of lines.
        all_lines = []

        # Loop through each rhyme group to find lines that satisfy the conditions.
        distinct_line_conds.each do |rhyme_letter, line_conds|

          # The conditions that will be passed to '#conditional_sample'.
          # This is an array of procs, one for each line.
          conditions = line_conds.map do |cond|
            proc { |arr, elem| diff_end(arr, elem) and validate_line(elem, cond)}
          end

          # Get all rhymes from the database with at least as many final
          #   words as there are lines to be matched.
          rhymes = nil

          # If all the lines include a 'regex' condition,
          #   then we can specify to only query for matching lines.
          regex_all = regex_for_all line_conds

          # If all the lines include a 'syllable' condition,
          #   then we can specify to only query for matching lines.
          min_max = syllable_min_max line_conds
          rhymes = @corpus.rhymes_by_count(line_conds.count, min_max)

          # Get just the rhyme part of the hash.
          rhymes = rhymes.map{ |i| i['rhyme'] }
          rhymes = rhymes - rhymes_already_used

          # For each rhyme, get all lines and try to sastify all conditions.
          out = []
          rhymes.shuffle.each do |rhyme|
            out = try_rhyme(conditions, rhyme, min_max, regex_all)
            break if !out.empty?
          end
          if out.empty?
            msg = 'ERROR: Not enough rhyming lines in the input.'
            if poetic_form[:proper]
              msg += "\n       Perhaps try again using the -p option."
            end
            return handle_error msg
          end
          rhymes_already_used << out.first['rhyme']

          # Add the line number back to the array.
          line_conds.count.times do |i|
            out[i]['line_number'] = line_conds[i][:line]
          end

          out.each do |i|
            all_lines << i
          end
        end

        # Transpose lines to their actual location.
        poem_lines = []
        all_lines.each do |line|
          poem_lines[line['line_number'] - 1] = line['line'].dup
        end

        # Go back to the [by_line] array and find all the refrain line nos.
        refrains = Hash.new { |h,k| h[k] = [] }
        by_line.reject{ |i| i[:rhyme] == ' ' }.each do |line|
          if line[:refrain]
            refrains[line[:refrain]] << line[:line]
          end
        end
        refrains.keys.each do |k|
          refrains[k].sort!
        end

        # Use the first refrain line and repeat it for the others.
        refrains.each do |key, values|
          values[1..-1].each do |i|
            poem_lines[i-1] = poem_lines[values.first-1]
          end
        end

        # Do the same for [:exact] lines.
        poetic_form[:rhyme].each.with_index do |line, index|
          poem_lines[index] = line[:exact] if line[:exact]
        end

        # Carry out transformations, if necessary.
        the_poem = poem_lines
        if poetic_form[:transform]

          # Due to the 'merge_hashes' above, each 'poetic_form[:transform]'
          #   value may contain an array of procs.
          poetic_form[:transform].each do |key, procs|
            begin
              # This is to ensure that e.g. '-2' will access from the end.
              i = (key > 0) ? key - 1 : key
              [*procs].each do |proc|
                the_poem[i] = proc.call(the_poem[i], i + 1, poem_lines).to_s
              end
            rescue
            end
          end
        end

        the_poem
      end

      # Loop through the rhymes until we find one that works.
      # (In a reasonable time-frame)
      def try_rhyme conditions, rhyme, syllable_min_max = nil, regex_all = nil
        output = []
        lines = @corpus.lines_by_rhyme(rhyme, syllable_min_max)

        # To reduce the number of permutations, reject lines
        #   that do not match any of the lines regex.
        lines.reject! { |i| !(i['line'].match(regex_all)) } if regex_all

        begin
          Timeout::timeout(2) do
            output = lines.shuffle.conditional_sample(conditions)
          end
        rescue
          output = []
        end
        output
      end

      # Find min and max syllable count from the conditions.
      def syllable_min_max line_conds
        min_max = nil
        if line_conds.all?{ |i| i[:syllable] }
          min = line_conds.min do |a, b|
            [*a[:syllable]].min <=> [*b[:syllable]].min
          end[:syllable]
          max = line_conds.max do |a, b|
            [*a[:syllable]].max <=> [*b[:syllable]].max
          end[:syllable]
          min_max = { min: [*min].min, max: [*max].max }
          min_max = nil if min_max[:max] == 0
        end
        min_max
      end

      # If every line has a regex, then return a regex union.
      def regex_for_all line_conds
        output = nil
        if line_conds.all?{ |i| i[:regex] }
          all_regex = line_conds.map{ |i| i[:regex] }
          output = Regexp.union all_regex.flatten
        end
        output
      end

  end

end

################################################################################
