lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'notes/version'

Gem::Specification.new do |spec|
  spec.name        = 'notes'
  spec.version     = Notes::VERSION
  spec.date        = '2013-03-15'
  spec.summary     = "Generate release notes!"
  spec.description = "Gem to generate release notes from commits\nGet logs between two release tags"
  spec.authors     = ["Vu Ngo"]
  spec.email       = 'vu_ngo@yahoo.com'
  spec.files       = Dir['lib/**/*.rb'] + Dir['bin/*']
  spec.executables = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files  = Dir.glob('test/**/*.rb')
  spec.homepage    = 'http://github.com/vu-ngo/notes'

  spec.require_paths = ["lib"]

  spec.add_dependency "git"
  spec.add_dependency "thor"
  spec.add_dependency "mail"
  spec.add_dependency "github_api"
  spec.add_dependency "jiralicious"
  spec.add_dependency "pivotal-tracker"

  spec.add_development_dependency "rake"
end
