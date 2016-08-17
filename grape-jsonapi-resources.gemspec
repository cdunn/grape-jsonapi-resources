# -*- encoding: utf-8 -*-
require File.expand_path('../lib/grape-jsonapi-resources/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Cary Dunn']
  gem.email         = ['cary.dunn@gmail.com']
  gem.summary       = 'Use jsonapi-resources in grape'
  gem.description   = 'Provides a Formatter for the Grape API DSL to emit objects serialized with jsonapi-resources.'
  gem.homepage      = 'https://github.com/cdunn/grape-jsonapi-resources'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  gem.name          = 'grape-jsonapi-resources'
  gem.require_paths = ['lib']
  gem.version       = Grape::JSONAPIResources::VERSION
  gem.licenses      = ['MIT']

  gem.add_dependency 'grape'
  gem.add_dependency 'jsonapi-resources', '>= 0.5.0'

  gem.add_development_dependency 'rails', '>= 5.0.0'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'rake'
end
