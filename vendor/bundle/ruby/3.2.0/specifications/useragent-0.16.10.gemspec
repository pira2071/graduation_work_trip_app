# -*- encoding: utf-8 -*-
# stub: useragent 0.16.10 ruby lib

Gem::Specification.new do |s|
  s.name = "useragent".freeze
  s.version = "0.16.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Joshua Peek".freeze, "Garry Shutler".freeze]
  s.date = "2018-02-12"
  s.description = "HTTP User Agent parser".freeze
  s.email = "garry@robustsoftware.co.uk".freeze
  s.homepage = "https://github.com/gshutler/useragent".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "HTTP User Agent parser".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
end