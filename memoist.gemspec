# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "memoist"
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua Peek", "Tarmo T\u{e4}nav", "Jeremy Kemper", "Eugene Pimenov", "Xavier Noria", "Niels Ganser", "Carl Lerche & Yehuda Katz", "jeem", "Jay Pignata", "Damien Mathieu", "Jos\u{e9} Valim"]
  s.date = "2013-03-20"
  s.email = ["josh@joshpeek.com", "tarmo@itech.ee", "jeremy@bitsweat.net", "libc@mac.com", "fxn@hashref.com", "niels@herimedia.co", "wycats@gmail.com", "jeem@hughesorama.com", "john.pignata@gmail.com", "42@dmathieu.com", "jose.valim@gmail.com"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "test/memoist_test.rb", "test/test_helper.rb", "lib/memoist", "lib/memoist/core_ext", "lib/memoist/core_ext/singleton_class.rb", "lib/memoist.rb"]
  s.homepage = "https://github.com/matthewrudy/memoist"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.25"
  s.summary = "memoize methods invocation"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
