# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slide/version'

Gem::Specification.new do |spec|
  spec.name          = "slide"
  spec.version       = Slide::VERSION
  spec.authors       = ["Michael Crismali"]
  spec.email         = ["michael.crismali@gmail.com"]
  spec.description   = %q{Compiles JavaScript from Ruby}
  spec.summary       = %q{Takes Ruby, turns it to CoffeeScript, then turns that into JavaScript}
  spec.homepage      = "https://github.com/michaelcrismali/Slide"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "parser"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "fuubar"
end
