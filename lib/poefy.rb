#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Line-based, used only to rearrange lines of text, not create new lines.
# Also uses 'wordfilter' to get rid of yucky words.
#
# https://en.wikipedia.org/wiki/Category:Western_medieval_lyric_forms
# https://en.wikipedia.org/wiki/Virelai
# https://en.wikipedia.org/wiki/List_of_compositions_by_Guillaume_de_Machaut#Virelais
################################################################################

require 'conditional_sample'
require 'ruby_rhymes'
require 'wordfilter'
require 'humanize'
require 'tempfile'
require 'sqlite3'
require 'timeout'

require_relative 'poefy/version.rb'
require_relative 'poefy/self.rb'
require_relative 'poefy/poefy_gen_base.rb'
require_relative 'poefy/generation.rb'
require_relative 'poefy/poetic_forms.rb'
require_relative 'poefy/poetic_form_from_text.rb'
require_relative 'poefy/string_manipulation.rb'
require_relative 'poefy/handle_error.rb'
require_relative 'poefy/database.rb'
require_relative 'poefy/conditional_sample.rb'
require_relative 'poefy/core_extensions/array.rb'

################################################################################

# Create a database from text lines.
# Read the database to generate poetry.
module Poefy

  class PoefyGen

    include Poefy::PoefyGenBase
    include Poefy::Generation
    include Poefy::PoeticForms
    include Poefy::PoeticFormFromText
    include Poefy::StringManipulation
    include Poefy::ConditionalSample
    include Poefy::HandleError

  end

end

################################################################################
