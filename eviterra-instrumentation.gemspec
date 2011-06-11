# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "eviterra-instrumentation/version"

Gem::Specification.new do |s|
  s.name        = "eviterra-instrumentation"
  s.version     = Eviterra::Instrumentation::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["codesnik"]
  s.email       = ["a.trofimenko@eviterra.com"]
  s.homepage    = ""
  s.summary     = %q{http loggers and subscribers for rails}
  s.description = %q{curl, net/http, etc.}

  s.rubyforge_project = "eviterra-instrumentation"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
