# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pom2spec/version"

Gem::Specification.new do |s|
  s.name        = "pom2spec"
  s.version     = Pom2spec::VERSION
  s.authors     = ["Duncan Mac-Vicar P"]
  s.email       = ["dmacvicar@suse.de"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "pom2spec"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency 'clamp'
  s.add_runtime_dependency 'open-uri-cached'
  s.add_runtime_dependency 'versionomy'
end
