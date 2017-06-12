# -*- encoding: utf-8 -*-
# stub: rails_ops 1.0.0.beta1 ruby lib

Gem::Specification.new do |s|
  s.name = "rails_ops".freeze
  s.version = "1.0.0.beta1"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sitrox".freeze]
  s.date = "2017-06-12"
  s.files = [".gitignore".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "bin/console".freeze, "bin/setup".freeze, "lib/rails_ops.rb".freeze, "lib/rails_ops/version.rb".freeze, "rails_ops.gemspec".freeze, "test/rails_ops_test.rb".freeze, "test/test_helper.rb".freeze]
  s.rubygems_version = "2.6.6".freeze
  s.summary = "A skeleton that allows extracting queries into atomic, reusable classes.".freeze
  s.test_files = ["test/rails_ops_test.rb".freeze, "test/test_helper.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_development_dependency(%q<yard>.freeze, [">= 0"])
      s.add_development_dependency(%q<rubocop>.freeze, ["= 0.37.1"])
      s.add_development_dependency(%q<redcarpet>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<schemacop>.freeze, ["~> 2.0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_dependency(%q<yard>.freeze, [">= 0"])
      s.add_dependency(%q<rubocop>.freeze, ["= 0.37.1"])
      s.add_dependency(%q<redcarpet>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_dependency(%q<activerecord>.freeze, [">= 0"])
      s.add_dependency(%q<schemacop>.freeze, ["~> 2.0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.37.1"])
    s.add_dependency(%q<redcarpet>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_dependency(%q<schemacop>.freeze, ["~> 2.0"])
  end
end