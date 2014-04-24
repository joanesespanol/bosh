# coding: utf-8
require File.expand_path('../lib/cloud/agility/version', __FILE__)

# Copyright (c) 2013 ServiceMesh, Inc.

version = Bosh::AgilityCloud::VERSION

Gem::Specification.new do |s|
  s.name                  = 'bosh_agility_cpi'
  s.version               = version
  s.platform              = Gem::Platform::RUBY
  s.summary               = 'BOSH AGILITY CPI'
  s.description           = "BOSH AGILITY CPI\n#{`git rev-parse HEAD`[0, 6]}"
  s.author                = 'ServiceMesh, Inc.'
  s.homepage              = 'https://github.com/cloudfoundry/bosh'
  s.license               = 'Apache 2.0'
  s.email                 = 'support@servicemesh.com'
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.3')

  s.files                 = `git ls-files -- bin/* lib/* scripts/*`.split("\n") + %w(README.md)
  s.require_path          = 'lib'
  s.bindir                = 'bin'
  s.executables           = %w(bosh_agility_console)

  s.add_dependency 'rjb', '>=1.4.9'
end
