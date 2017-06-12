require "bundler/gem_tasks"
require "rake/testtask"

task :default => :test

task :gemspec do
  gemspec = Gem::Specification.new do |spec|
    spec.name          = 'rails_ops'
    spec.version       = IO.read('VERSION').chomp
    spec.authors       = ['Sitrox']
    spec.summary       = 'A skeleton that allows extracting queries into atomic, reusable classes.'
    spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    spec.executables   = []
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ['lib']

    spec.add_development_dependency 'bundler', '~> 1.3'
    spec.add_development_dependency 'rake'
    spec.add_development_dependency 'sqlite3'
    spec.add_development_dependency 'yard'
    spec.add_development_dependency 'rubocop', '0.37.1'
    spec.add_development_dependency 'redcarpet'
    spec.add_dependency 'minitest'
    spec.add_dependency 'activesupport'
    spec.add_dependency 'activerecord'
    spec.add_dependency 'schemacop', '~> 2.0'
  end

  File.open('rails_ops.gemspec', 'w') { |f| f.write(gemspec.to_ruby.strip) }
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = 'test/rails_ops/**/*_test.rb'
  t.verbose = false
  t.libs << 'test'
end
