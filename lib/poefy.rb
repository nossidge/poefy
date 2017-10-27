#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Create a database from text lines.
# Read the database to generate poetry.
################################################################################

require 'conditional_sample'
require 'ruby_rhymes'
require 'wordfilter'
require 'humanize'
require 'timeout'
require 'yaml'

require_relative 'poefy/version.rb'
require_relative 'poefy/self.rb'
require_relative 'poefy/db_type.rb'
require_relative 'poefy/poem_base.rb'
require_relative 'poefy/generation.rb'
require_relative 'poefy/poetic_forms.rb'
require_relative 'poefy/poetic_form_from_text.rb'
require_relative 'poefy/string_manipulation.rb'
require_relative 'poefy/handle_error.rb'
require_relative 'poefy/database.rb'
require_relative 'poefy/conditional_sample.rb'
require_relative 'poefy/core_extensions/array.rb'

################################################################################

module Poefy

  class Poem

    include Poefy::PoemBase
    include Poefy::Generation
    include Poefy::PoeticForms
    include Poefy::PoeticFormFromText
    include Poefy::StringManipulation
    include Poefy::ConditionalSample

  end

end

################################################################################
