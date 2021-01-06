# -*- encoding: utf-8 -*-
# stub: rails_ops 1.1.15 ruby lib

Gem::Specification.new do |s|
  s.name = "rails_ops".freeze
  s.version = "1.1.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sitrox".freeze]
  s.date = "2021-01-06"
  s.files = [".gitignore".freeze, ".releaser_config".freeze, ".rubocop.yml".freeze, ".travis.yml".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "VERSION".freeze, "lib/rails_ops.rb".freeze, "lib/rails_ops/authorization_backend/abstract.rb".freeze, "lib/rails_ops/authorization_backend/can_can_can.rb".freeze, "lib/rails_ops/configuration.rb".freeze, "lib/rails_ops/context.rb".freeze, "lib/rails_ops/controller_mixin.rb".freeze, "lib/rails_ops/exceptions.rb".freeze, "lib/rails_ops/hooked_job.rb".freeze, "lib/rails_ops/hookup.rb".freeze, "lib/rails_ops/hookup/dsl.rb".freeze, "lib/rails_ops/hookup/dsl_validator.rb".freeze, "lib/rails_ops/hookup/hook.rb".freeze, "lib/rails_ops/log_subscriber.rb".freeze, "lib/rails_ops/mixins.rb".freeze, "lib/rails_ops/mixins/authorization.rb".freeze, "lib/rails_ops/mixins/log_settings.rb".freeze, "lib/rails_ops/mixins/model.rb".freeze, "lib/rails_ops/mixins/model/authorization.rb".freeze, "lib/rails_ops/mixins/model/nesting.rb".freeze, "lib/rails_ops/mixins/param_authorization.rb".freeze, "lib/rails_ops/mixins/policies.rb".freeze, "lib/rails_ops/mixins/require_context.rb".freeze, "lib/rails_ops/mixins/routes.rb".freeze, "lib/rails_ops/mixins/schema_validation.rb".freeze, "lib/rails_ops/mixins/sub_ops.rb".freeze, "lib/rails_ops/model_casting.rb".freeze, "lib/rails_ops/model_mixins.rb".freeze, "lib/rails_ops/model_mixins/ar_extension.rb".freeze, "lib/rails_ops/model_mixins/parent_op.rb".freeze, "lib/rails_ops/model_mixins/virtual_attributes.rb".freeze, "lib/rails_ops/model_mixins/virtual_attributes/virtual_column_wrapper.rb".freeze, "lib/rails_ops/model_mixins/virtual_has_one.rb".freeze, "lib/rails_ops/model_mixins/virtual_model_name.rb".freeze, "lib/rails_ops/operation.rb".freeze, "lib/rails_ops/operation/model.rb".freeze, "lib/rails_ops/operation/model/create.rb".freeze, "lib/rails_ops/operation/model/destroy.rb".freeze, "lib/rails_ops/operation/model/load.rb".freeze, "lib/rails_ops/operation/model/update.rb".freeze, "lib/rails_ops/patches/active_type_patch.rb".freeze, "lib/rails_ops/profiler.rb".freeze, "lib/rails_ops/profiler/node.rb".freeze, "lib/rails_ops/railtie.rb".freeze, "lib/rails_ops/scoped_env.rb".freeze, "lib/rails_ops/virtual_model.rb".freeze, "rails_ops.gemspec".freeze, "test/db/models.rb".freeze, "test/db/schema.rb".freeze, "test/dummy/Rakefile".freeze, "test/dummy/app/assets/config/manifest.js".freeze, "test/dummy/app/assets/images/.keep".freeze, "test/dummy/app/assets/javascripts/application.js".freeze, "test/dummy/app/assets/javascripts/cable.js".freeze, "test/dummy/app/assets/javascripts/channels/.keep".freeze, "test/dummy/app/assets/stylesheets/application.css".freeze, "test/dummy/app/channels/application_cable/channel.rb".freeze, "test/dummy/app/channels/application_cable/connection.rb".freeze, "test/dummy/app/controllers/application_controller.rb".freeze, "test/dummy/app/controllers/concerns/.keep".freeze, "test/dummy/app/helpers/application_helper.rb".freeze, "test/dummy/app/jobs/application_job.rb".freeze, "test/dummy/app/mailers/application_mailer.rb".freeze, "test/dummy/app/models/application_record.rb".freeze, "test/dummy/app/models/concerns/.keep".freeze, "test/dummy/app/models/group.rb".freeze, "test/dummy/app/views/layouts/application.html.erb".freeze, "test/dummy/app/views/layouts/mailer.html.erb".freeze, "test/dummy/app/views/layouts/mailer.text.erb".freeze, "test/dummy/bin/bundle".freeze, "test/dummy/bin/rails".freeze, "test/dummy/bin/rake".freeze, "test/dummy/bin/setup".freeze, "test/dummy/bin/update".freeze, "test/dummy/bin/yarn".freeze, "test/dummy/config.ru".freeze, "test/dummy/config/application.rb".freeze, "test/dummy/config/boot.rb".freeze, "test/dummy/config/cable.yml".freeze, "test/dummy/config/database.yml".freeze, "test/dummy/config/environment.rb".freeze, "test/dummy/config/environments/development.rb".freeze, "test/dummy/config/environments/production.rb".freeze, "test/dummy/config/environments/test.rb".freeze, "test/dummy/config/initializers/application_controller_renderer.rb".freeze, "test/dummy/config/initializers/assets.rb".freeze, "test/dummy/config/initializers/backtrace_silencers.rb".freeze, "test/dummy/config/initializers/cookies_serializer.rb".freeze, "test/dummy/config/initializers/filter_parameter_logging.rb".freeze, "test/dummy/config/initializers/inflections.rb".freeze, "test/dummy/config/initializers/mime_types.rb".freeze, "test/dummy/config/initializers/rails_ops.rb".freeze, "test/dummy/config/initializers/wrap_parameters.rb".freeze, "test/dummy/config/locales/en.yml".freeze, "test/dummy/config/puma.rb".freeze, "test/dummy/config/routes.rb".freeze, "test/dummy/config/secrets.yml".freeze, "test/dummy/config/spring.rb".freeze, "test/dummy/db/schema.rb".freeze, "test/dummy/lib/assets/.keep".freeze, "test/dummy/log/.keep".freeze, "test/dummy/package.json".freeze, "test/dummy/public/404.html".freeze, "test/dummy/public/422.html".freeze, "test/dummy/public/500.html".freeze, "test/dummy/public/apple-touch-icon-precomposed.png".freeze, "test/dummy/public/apple-touch-icon.png".freeze, "test/dummy/public/favicon.ico".freeze, "test/dummy/tmp/.keep".freeze, "test/test_helper.rb".freeze, "test/unit/rails_ops/mixins/model/nesting.rb".freeze, "test/unit/rails_ops/mixins/policies_test.rb".freeze, "test/unit/rails_ops/operation/model/create_test.rb".freeze, "test/unit/rails_ops/operation/model/load_test.rb".freeze, "test/unit/rails_ops/operation/model/update_test.rb".freeze, "test/unit/rails_ops/operation/model_test.rb".freeze, "test/unit/rails_ops/operation_test.rb".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "An operations service layer for rails projects.".freeze
  s.test_files = ["test/db/models.rb".freeze, "test/db/schema.rb".freeze, "test/dummy/Rakefile".freeze, "test/dummy/app/assets/config/manifest.js".freeze, "test/dummy/app/assets/images/.keep".freeze, "test/dummy/app/assets/javascripts/application.js".freeze, "test/dummy/app/assets/javascripts/cable.js".freeze, "test/dummy/app/assets/javascripts/channels/.keep".freeze, "test/dummy/app/assets/stylesheets/application.css".freeze, "test/dummy/app/channels/application_cable/channel.rb".freeze, "test/dummy/app/channels/application_cable/connection.rb".freeze, "test/dummy/app/controllers/application_controller.rb".freeze, "test/dummy/app/controllers/concerns/.keep".freeze, "test/dummy/app/helpers/application_helper.rb".freeze, "test/dummy/app/jobs/application_job.rb".freeze, "test/dummy/app/mailers/application_mailer.rb".freeze, "test/dummy/app/models/application_record.rb".freeze, "test/dummy/app/models/concerns/.keep".freeze, "test/dummy/app/models/group.rb".freeze, "test/dummy/app/views/layouts/application.html.erb".freeze, "test/dummy/app/views/layouts/mailer.html.erb".freeze, "test/dummy/app/views/layouts/mailer.text.erb".freeze, "test/dummy/bin/bundle".freeze, "test/dummy/bin/rails".freeze, "test/dummy/bin/rake".freeze, "test/dummy/bin/setup".freeze, "test/dummy/bin/update".freeze, "test/dummy/bin/yarn".freeze, "test/dummy/config.ru".freeze, "test/dummy/config/application.rb".freeze, "test/dummy/config/boot.rb".freeze, "test/dummy/config/cable.yml".freeze, "test/dummy/config/database.yml".freeze, "test/dummy/config/environment.rb".freeze, "test/dummy/config/environments/development.rb".freeze, "test/dummy/config/environments/production.rb".freeze, "test/dummy/config/environments/test.rb".freeze, "test/dummy/config/initializers/application_controller_renderer.rb".freeze, "test/dummy/config/initializers/assets.rb".freeze, "test/dummy/config/initializers/backtrace_silencers.rb".freeze, "test/dummy/config/initializers/cookies_serializer.rb".freeze, "test/dummy/config/initializers/filter_parameter_logging.rb".freeze, "test/dummy/config/initializers/inflections.rb".freeze, "test/dummy/config/initializers/mime_types.rb".freeze, "test/dummy/config/initializers/rails_ops.rb".freeze, "test/dummy/config/initializers/wrap_parameters.rb".freeze, "test/dummy/config/locales/en.yml".freeze, "test/dummy/config/puma.rb".freeze, "test/dummy/config/routes.rb".freeze, "test/dummy/config/secrets.yml".freeze, "test/dummy/config/spring.rb".freeze, "test/dummy/db/schema.rb".freeze, "test/dummy/lib/assets/.keep".freeze, "test/dummy/log/.keep".freeze, "test/dummy/package.json".freeze, "test/dummy/public/404.html".freeze, "test/dummy/public/422.html".freeze, "test/dummy/public/500.html".freeze, "test/dummy/public/apple-touch-icon-precomposed.png".freeze, "test/dummy/public/apple-touch-icon.png".freeze, "test/dummy/public/favicon.ico".freeze, "test/dummy/tmp/.keep".freeze, "test/test_helper.rb".freeze, "test/unit/rails_ops/mixins/model/nesting.rb".freeze, "test/unit/rails_ops/mixins/policies_test.rb".freeze, "test/unit/rails_ops/operation/model/create_test.rb".freeze, "test/unit/rails_ops/operation/model/load_test.rb".freeze, "test/unit/rails_ops/operation/model/update_test.rb".freeze, "test/unit/rails_ops/operation/model_test.rb".freeze, "test/unit/rails_ops/operation_test.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["= 0.47.1"])
    s.add_runtime_dependency(%q<active_type>.freeze, [">= 1.3.0"])
    s.add_runtime_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<rails>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<request_store>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<schemacop>.freeze, ["~> 2.4.2"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.47.1"])
    s.add_dependency(%q<active_type>.freeze, [">= 1.3.0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<rails>.freeze, [">= 0"])
    s.add_dependency(%q<request_store>.freeze, [">= 0"])
    s.add_dependency(%q<schemacop>.freeze, ["~> 2.4.2"])
  end
end