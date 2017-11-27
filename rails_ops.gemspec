# -*- encoding: utf-8 -*-
# stub: rails_ops 1.0.0.beta6 ruby lib

Gem::Specification.new do |s|
  s.name = "rails_ops".freeze
  s.version = "1.0.0.beta6"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sitrox".freeze]
  s.date = "2017-11-27"
  s.files = [".gitignore".freeze, ".releaser_config".freeze, ".rubocop.yml".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "RUBY_VERSION".freeze, "Rakefile".freeze, "VERSION".freeze, "lib/rails_ops.rb".freeze, "lib/rails_ops/authorization_backend/abstract.rb".freeze, "lib/rails_ops/authorization_backend/can_can_can.rb".freeze, "lib/rails_ops/configuration.rb".freeze, "lib/rails_ops/context.rb".freeze, "lib/rails_ops/controller_mixin.rb".freeze, "lib/rails_ops/exceptions.rb".freeze, "lib/rails_ops/hooked_job.rb".freeze, "lib/rails_ops/hookup.rb".freeze, "lib/rails_ops/hookup/dsl.rb".freeze, "lib/rails_ops/hookup/dsl_validator.rb".freeze, "lib/rails_ops/hookup/hook.rb".freeze, "lib/rails_ops/log_subscriber.rb".freeze, "lib/rails_ops/mixins.rb".freeze, "lib/rails_ops/mixins/authorization.rb".freeze, "lib/rails_ops/mixins/log_settings.rb".freeze, "lib/rails_ops/mixins/model.rb".freeze, "lib/rails_ops/mixins/model/authorization.rb".freeze, "lib/rails_ops/mixins/model/nesting.rb".freeze, "lib/rails_ops/mixins/policies.rb".freeze, "lib/rails_ops/mixins/require_context.rb".freeze, "lib/rails_ops/mixins/routes.rb".freeze, "lib/rails_ops/mixins/schema_validation.rb".freeze, "lib/rails_ops/mixins/sub_ops.rb".freeze, "lib/rails_ops/model_casting.rb".freeze, "lib/rails_ops/model_mixins.rb".freeze, "lib/rails_ops/model_mixins/ar_extension.rb".freeze, "lib/rails_ops/model_mixins/parent_op.rb".freeze, "lib/rails_ops/model_mixins/protected_attributes.rb".freeze, "lib/rails_ops/model_mixins/virtual_attributes.rb".freeze, "lib/rails_ops/model_mixins/virtual_attributes/virtual_column_wrapper.rb".freeze, "lib/rails_ops/model_mixins/virtual_has_one.rb".freeze, "lib/rails_ops/operation.rb".freeze, "lib/rails_ops/operation/model.rb".freeze, "lib/rails_ops/operation/model/create.rb".freeze, "lib/rails_ops/operation/model/destroy.rb".freeze, "lib/rails_ops/operation/model/load.rb".freeze, "lib/rails_ops/operation/model/update.rb".freeze, "lib/rails_ops/patches/active_type_patch.rb".freeze, "lib/rails_ops/profiler.rb".freeze, "lib/rails_ops/profiler/node.rb".freeze, "lib/rails_ops/railtie.rb".freeze, "lib/rails_ops/scoped_env.rb".freeze, "lib/rails_ops/virtual_model.rb".freeze, "rails_ops.gemspec".freeze, "test/db/models.rb".freeze, "test/db/schema.rb".freeze, "test/rails_ops/operation/example_test.rb".freeze, "test/test_helper.rb".freeze]
  s.rubygems_version = "2.6.6".freeze
  s.summary = "An operations service layer for rails projects.".freeze
  s.test_files = ["test/db/models.rb".freeze, "test/db/schema.rb".freeze, "test/rails_ops/operation/example_test.rb".freeze, "test/test_helper.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_development_dependency(%q<yard>.freeze, [">= 0"])
      s.add_development_dependency(%q<rubocop>.freeze, ["= 0.47.1"])
      s.add_development_dependency(%q<redcarpet>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<active_type>.freeze, ["~> 0.7.1"])
      s.add_runtime_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activejob>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<schemacop>.freeze, ["~> 2.0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_dependency(%q<yard>.freeze, [">= 0"])
      s.add_dependency(%q<rubocop>.freeze, ["= 0.47.1"])
      s.add_dependency(%q<redcarpet>.freeze, [">= 0"])
      s.add_dependency(%q<active_type>.freeze, ["~> 0.7.1"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_dependency(%q<activerecord>.freeze, [">= 0"])
      s.add_dependency(%q<activejob>.freeze, [">= 0"])
      s.add_dependency(%q<schemacop>.freeze, ["~> 2.0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.47.1"])
    s.add_dependency(%q<redcarpet>.freeze, [">= 0"])
    s.add_dependency(%q<active_type>.freeze, ["~> 0.7.1"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_dependency(%q<activejob>.freeze, [">= 0"])
    s.add_dependency(%q<schemacop>.freeze, ["~> 2.0"])
  end
end