require 'bundler/setup'
Bundler.setup

require 'tempfile'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'poefy'

RSpec.configure do |config|
  # some (optional) config here
end
