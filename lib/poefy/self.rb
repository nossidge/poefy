#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Class methods for Poefy module.
################################################################################

module Poefy
  class << self

    # Array of all databases (SQLite) or tables (Postgres)
    # Does not include databases used for testing.
    def corpora
      Poefy::Database.list
    end
    alias_method :tables,    :corpora
    alias_method :databases, :corpora

    # Same, but with the description of the corpus too.
    def corpora_with_desc
      Poefy::Database.list_with_desc
    end
    alias_method :tables_with_desc,    :corpora_with_desc
    alias_method :databases_with_desc, :corpora_with_desc

    # Array of all names of poetic forms.
    def poetic_forms
      PoeticForms::POETIC_FORMS.keys.reject { |i| i == :default }
    end

    # Find the root of the directory tree.
    def root
      File.expand_path('../../../', __FILE__)
    end

  end
end

################################################################################
