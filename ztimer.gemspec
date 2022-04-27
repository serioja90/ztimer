# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ztimer/version'

Gem::Specification.new do |spec|
  spec.name          = 'ztimer'
  spec.version       = Ztimer::VERSION
  spec.authors       = ['Groza Sergiu']
  spec.email         = ['serioja90@gmail.com']

  spec.summary       = %(An asyncrhonous timer)
  spec.description   = %(Ruby asyncrhonous timer that allows you to enqueue tasks to be executed asyncrhonously after a delay)
  spec.homepage      = 'https://github.com/serioja90/ztimer'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5'

  spec.add_development_dependency 'bundler', '~>2.2', '>= 2.2.33'
  spec.add_development_dependency 'rake', '~>12.3', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
