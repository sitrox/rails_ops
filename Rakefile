require 'bundler/gem_tasks'

require 'rake/testtask'

task default: :test

task :gemspec do
  gemspec = Gem::Specification.new do |spec|
    spec.name          = 'rails_ops'
    spec.version       = File.read('VERSION').chomp
    spec.authors       = ['Sitrox']
    spec.summary       = 'An operations service layer for rails projects.'
    spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    spec.executables   = []
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ['lib']

    spec.add_development_dependency 'appraisal'
    spec.add_development_dependency 'bundler'
    spec.add_development_dependency 'rake'
    spec.add_development_dependency 'sqlite3'
    spec.add_development_dependency 'cancancan'
    spec.add_development_dependency 'pry'
    spec.add_development_dependency 'colorize'
    spec.add_development_dependency 'rubocop', '1.45.1'
    spec.add_development_dependency 'sprockets-rails'
    spec.add_dependency 'active_type', '>= 1.3.0'
    spec.add_dependency 'minitest'
    spec.add_dependency 'rails'
    spec.add_dependency 'request_store'
    spec.add_dependency 'schemacop', '>= 2.4.2', '<= 3.1'
  end

  File.write('rails_ops.gemspec', gemspec.to_ruby.strip)
end

Rake::TestTask.new do |t|
  t.pattern = 'test/unit/**/*_test.rb'
  t.verbose = false
  t.libs << 'test'
  t.warning = false
end
