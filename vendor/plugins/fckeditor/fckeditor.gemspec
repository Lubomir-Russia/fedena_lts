# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fckeditor/version'

Gem::Specification.new do |spec|
  spec.name          = "fckeditor"
  spec.version       = Fckeditor::VERSION
  spec.authors       = ["Fedena"]
  spec.email         = ["info@.projectfedena.org"]
  spec.description   = %q{Fedena SIS Long Term Support edition}
  spec.summary       = %q{}
  spec.homepage      = "http://www.projectfedena.org/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
