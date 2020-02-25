require 'bundler/gem_tasks'

require 'rake/testtask'

task default: :test

task :gemspec do
  gemspec = Gem::Specification.new do |spec|
    spec.name          = 'rails_ops'
    spec.version       = IO.read('VERSION').chomp
    spec.authors       = ['Sitrox']
    spec.summary       = 'An operations service layer for rails projects.'
    spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    spec.executables   = []
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ['lib']

    spec.add_development_dependency 'bundler'
    spec.add_development_dependency 'rake'
    spec.add_development_dependency 'sqlite3'
    spec.add_development_dependency 'rubocop', '0.47.1'
    spec.add_dependency 'active_type', '~> 0.7.1'
    spec.add_dependency 'minitest'
    spec.add_dependency 'rails'
    spec.add_dependency 'request_store'
    spec.add_dependency 'schemacop', '~> 2.4.2'
  end

  File.open('rails_ops.gemspec', 'w') { |f| f.write(gemspec.to_ruby.strip) }
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = 'test/unit/**/*_test.rb'
  t.verbose = false
  t.libs << 'test'
  t.warning = false
end
