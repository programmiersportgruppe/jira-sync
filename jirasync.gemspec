# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jirasync/version'

Gem::Specification.new do |s|
  s.name         = 'jirasync'
  s.summary      = 'jirasync synchronises jira projects to the local file system'
  s.description  = 'jirasync synchronises tickets from a jira project to the local
                    file system. It supports a complete fetch operation as well as
                    an incremental update.

                    Each ticket is stored in a simple, pretty printed JSON file.'
  s.version      = JiraSync::VERSION
  s.platform     = Gem::Platform::RUBY

  s.files        = ['bin/jira-sync']

  s.bindir = 'bin'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.author      = 'Felix Leipold'
  s.email       = ''
  s.homepage    = 'https://github.com/programmiersportgruppe/jira-sync'


  s.add_dependency('trollop')
  s.add_dependency('httparty')
  s.add_dependency('parallel')
  s.add_dependency('ruby-progressbar')
end
