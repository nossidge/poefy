# Encoding: UTF-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'poefy/version'

Gem::Specification.new do |s|
  s.name          = 'poefy'
  s.authors       = ['Paul Thompson']
  s.email         = ['nossidge@gmail.com']

  s.summary       = %q{Create rhyming poetry by rearranging lines of text}
  s.description   = %q{Create poems from an input text file, by generating and querying a SQLite database describing each line.Poems are created using a template to select lines from the database, according to closing rhyme, syllable count, and regex matching.}
  s.homepage      = 'https://github.com/nossidge/poefy'

  s.version       = Poefy.version_number
  s.date          = Poefy.version_date
  s.license       = 'GPL-3.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if s.respond_to?(:metadata)
    s.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.bindir        = 'bin'

  s.add_development_dependency('bundler', '~> 1.13')
  s.add_development_dependency('rake',    '~> 10.0')
  s.add_development_dependency('rspec',   '~> 3.0')

  s.add_runtime_dependency('sqlite3',     '~> 1.3', '>= 1.3.13')
  s.add_runtime_dependency('ruby_rhymes', '~> 0.1', '>= 0.1.2')
  s.add_runtime_dependency('wordfilter',  '~> 0.2', '>= 0.2.6')
end
