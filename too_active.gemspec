$:.push File.expand_path("../lib", __FILE__)

require 'too_active/version'

Gem::Specification.new do |spec|
  spec.name          = 'too_active'
  spec.version       = TooActive::VERSION
  spec.authors       = ['Peter Compernolle']

  spec.description   = "Maybe the way you're using ActiveSupport in your application is... too active?"
  spec.summary       = 'Analyze your application performance using ActiveSupport::Notifications'
  spec.homepage      = 'https://github.com/thelowlypeon/too_active'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'

  spec.add_dependency 'activesupport', '>= 4.0'
end
