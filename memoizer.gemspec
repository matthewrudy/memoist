# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "memoizer"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua Peek", "Tarmo T\u{e4}nav", "Jeremy Kemper", "Eugene Pimenov", "Xavier Noria", "Niels Ganser", "Carl Lerche & Yehuda Katz", "jeem", "Jay Pignata", "Damien Mathieu", "Jos\u{e9} Valim"]
  s.date = "2011-12-07"
  s.email = ["josh@joshpeek.com", "tarmo@itech.ee", "jeremy@bitsweat.net", "libc@mac.com", "fxn@hashref.com", "niels@herimedia.co", "wycats@gmail.com", "jeem@hughesorama.com", "john.pignata@gmail.com", "42@dmathieu.com", "jose.valim@gmail.com"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "test/memoizer_test.rb", "test/test_helper.rb", "lib/core_ext/singleton_class.rb", "lib/memoizer.rb"]
  s.homepage = "https://github.com/matthewrudy/memoizable"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "memoize methods invocation"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
