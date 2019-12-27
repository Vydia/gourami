# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gourami/version"

Gem::Specification.new do |spec|
  spec.name          = "gourami"
  spec.version       = Gourami::VERSION
  spec.authors       = ["TSMMark"]
  spec.email         = ["dev@vydia.com"]

  spec.summary       = %q{Keep your Routes, Controllers and Models thin.}
  spec.description   = %q{Create Plain Old Ruby Objects that take attributes, validate them, and perform an action.}
  spec.homepage      = "http://github.com/Vydia/gourami"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "filewatcher", "~> 1.1.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry", "~>0.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
