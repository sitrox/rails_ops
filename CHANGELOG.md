# Changelog

## 1.1.27 (2022-02-15)

* Add `module` option to `operation` generator

## 1.1.26 (2022-01-18)

* #25: Add test matrix for unit tests

* Add compatibility for Rails 7 and Ruby 3.1.0

## 1.1.25 (2022-01-17)

* #24: Add generator `operation` that generates a controller, operations and empty
  view files

## 1.1.24 (2021-11-24)

* Add support for STI in model operations

## 1.1.23 (2021-11-01)

* No changes to previous release

## 1.1.22 (2021-11-01)

* Add support for lazy model authorization

## 1.1.21 (2021-06-23)

* Fix using model operations in conjunction with Single Table Inheritance (STI)

## 1.1.20 (2021-02-18)

* Fix warnings with Ruby 2.7

## 1.1.19 (2021-02-16)

* Fix warnings with Ruby 2.7

## 1.1.18 (2021-02-16)

* Adapt signature of `schema3` method to support other types than hashes

## 1.1.17 (2021-02-10)

* Add operation class method `skip_schema_validation`

* Add operation instance method `validate_op_schema!`

## 1.1.16 (2021-01-26)

* Update dependency to support `schemacop` version 3

## 1.1.15 (2021-01-06)

* Allow `active_type >= 1.3.0`

## 1.1.14 (2020-12-22)

* Fix validation of unchanged nested models.

## 1.1.13 (2020-11-23)

* Update support for upcoming Schemacop 3

## 1.1.12 (2020-11-24)

* Add support for upcoming Schemacop 3. It is still backwards compatible and
  the schemacop schema version still defaults to 2.

  Note that support for the new Schemacop 3 features is not yet documented.

## 1.1.11 (2020-10-29)

* Add method `lazy_model` to `RailsOps::Operation::Model`

## 1.1.10 (2020-08-29)

* Fix parameter inspection bug introduced in 1.1.9.

## 1.1.9 (2020-08-28)

* Gracefully filter params when inspecting an operation. If the params included
  numeric keys in `rails < 6`, this lead to an error. This error is now handeled
  gracefully and params are not inspected.

* Do not call `inspect` every time an op is run

## 1.1.8 (2020-07-08)

* Fix bug where only the first hooked operation was called

## 1.1.7 (2020-06-18)

* Add controller / helper method `model?`

## 1.1.6 (2020-04-08)

* Fix suppressed validation errors by operations called via hookup. Now the
  exception {RailsOps::Exceptions::HookupOpValidationFailed} is thrown if a hook
  target operation throws a validation error throws a validation error

## 1.1.5 (2020-03-23)

* Upgrade `active_type` to `~> 1.3.0` for Rails 6 compatibility

## 1.1.4 (2020-03-10)

* Remove debug output.

## 1.1.3 (2020-03-05)

* Fix bug introduced in `1.1.0` where params of operations with a schemacop
  schema were not using "indifferent access" anymore.

## 1.1.2 (2020-03-02)

* Include the ControllerMixin after `ActionController::Base` has been loaded, as
  directly calling `ActionController::Base.send :include, RailsOps::ControllerMixin`
  in the railtie causes the `ActionController::Base` to be loaded during Initialization,
  which is undesirable and will be an error in future Rails versions.

## 1.1.1 (2020-03-02)

* Do not require default (CanCanCan) authorization backend anymore so that the
  Gem `cancancan` is not required by default anymore. If you are using the
  default authentication backend, add the following line to the top of your
  `config/initializers/rails_ops.rb` file:

  ```ruby
  require 'rails_ops/authorization_backend/can_can_can.rb'
  ``

## 1.1.0 (2020-02-25)

* **Breaking changes**:

  * Schema validations defined with `schema` are now always run **on operation
    instantiation** and not, as before, at time of `before_perform`.

  * The argument `policy_chain` for the static operation method `schema` is now
    removed.

  * Schema validation now overrides the `params` hash with the return value from
    Schemacop. This means that Schemacop defaults and casts now can be used for
    operation params (with both `params` and `osparams` methods).

  * RailsOps now requires `schemacop ~> 2.4.2`.

## 1.0.21 (2020-02-13)

* Exclude param named `format` from `op_params`.

## 1.0.20 (2020-02-13)

* Add param authorization functionality using `authorize_param`

## 1.0.19 (2020-02-11)

* Fix examples in readme

## 1.0.18 (2020-01-21)

* Pass option `required` to the underlying `belongs_to` in `virtual_has_one`.
  This fixes an issue where, in Rails > 5, all associations created with
  `virtual_has_one` were considered required.

## 1.0.17 (2020-01-17)

* Add global option `config.ensure_authorize_called` (defaults to
  `true` to be compatible with previous versions)

## 1.0.16 (2019-10-07)

* Add option `allow_id` to `nest_model_op` in order to allow passing IDs to
  sub-operations. Set to `false` by default to mimic current behavior.

## 1.0.15 (2019-09-23)

* Fix bug introduced in 1.0.14 where the controller mixin failed with an
  exception

## 1.0.14 (2019-09-23)

* Ensure compatibility with Rails 3.2.

## 1.0.13 (2019-08-27)

* Set the name of nested params to the modelname, not to the fieldname.
  This is a follow up from 1.0.11.

## 1.0.12 (2019-08-20)

* {RailsOps::Context#spawn} now dynamically inferrs current class name in order
  to spawn a new context. This allows you to subclass the context class and have
  it spawned with the correct class.

## 1.0.11 (2019-07-29)

* It is now possible to have nested model ops on belongs_to relations
  with explicit class_name.

## 1.0.10 (2019-07-23)

* Fix `defined?` calls in controller mixin so that the mixin can be used without
  defining `current_user` or `current_ability`.

## 1.0.9 (2019-05-29)

* Changes to development setup

## 1.0.8 (2019-05-29)

* Fix #14 Policy chain `after_perform` is never called.

## 1.0.7 (2019-04-25)

* It is now possible to add a policy in front of the policy chain
  instead of the end. It is however not guaranteed to be the first policy to be
  run since multiple policies can be prepended to the chain.  A prepended policy
  can't access the operation model, since it is not set yet.

  See PR#12.

## 1.0.6 (2019-04-10)

* Fix automatic controller mixin introduced in 1.0.4. Including the mixin into
  `ApplicationController` lead to random user-defined helpers not being loaded
  anymore. The mixin is now included into `ActionController::Base` instead.

## 1.0.5 (2019-04-09)

* Add missing controller mixin automatically so that no (undocumented) manual
  include is necessary.

## 1.0.4 (2019-04-03)

* Add global option `config.trigger_hookups_without_authorization` (defaults to
  `true` to be compatible with previous versions)

## 1.0.3 (2019-03-18)

* Add missing imports of required third-party gems

* Add policy chain `before_model_save` for model operations

* Add policy chain `before_nested_model_ops` for model operations

* If existing, use `ActiveSupport::ParameterFilter` over
  `ActionDispatch::Http::ParameterFilter` which is deprecated in Rails 6

* Fix error catching of nested model operations

* Fix error handling of sub operations

* Add `view` to operation contexts that contains the `view_context`. Only use
  this for frontend operations that are always called from within a controller.

* Expose `op_context` as a view helper method. This is useful for instantiating
  new (view) operations from within views and helpers.

## 1.0.2 (2019-01-29)

* Fix mass assignment protection errors under Rails 3

## 1.0.1 (2019-01-29)

* Fix reliance on `ActionController::Parameters`. Now the strong parameter
  check is only enforced if `ActionController::Parameters` actually exists.

* Fix missing `require`

* Fix compatibility with ruby < `2.3.0`

## 1.0.0 (2019-01-23)

* First stable release after being battle-tested over an extended period of
  time.

## Prior to 1.0.0 (beta releases)

### 1.0.0.beta15 (2018-12-11)

* Add method `authorize_called!` to manually mark authorization as called for a
  specific operation.

### 1.0.0.beta14 (2018-11-29)

* Fix bug with jRuby 9.2 where operation class name got mutated when inspecting
  it (see https://github.com/jruby/jruby/issues/5480).

### 1.0.0.beta13 (2018-10-15)

* Explain how to setup load paths in readme

### 1.0.0.beta12 (2018-08-14)

* Exclude param named `escape` from `op_params`.

### 1.0.0.beta11 (2018-07-31)

* Exclude param named `_` from `op_params`. This allows to use `cache: false`
  with `jQuery.ajax`.

### 1.0.0.beta10 (2018-07-18)

* Allow model name override for all models using `RailsOps::ModelMixins`. This
  means you can also specify a model name for models not inheriting from
  `RailsOps::VirtualModel`, i.e.:

  ```ruby
  model User, 'ModelNameOverride'
  ```

### 1.0.0.beta9 (2018-07-04)

* Keep stack trace on exceptions rethrown by `with_rollback_on_exception`.

### 1.0.0.beta8 (2018-05-15)

* Make sure that original state is always restored after calling
  `RailsOps.without_authorization`, even in case of an exception.

### 1.0.0.beta7 (2017-12-19)

* #2 Get rid of protected attributes functionality

### 1.0.0.beta6 (2017-11-27)

* Fix #6 Exceptions in profiler are not re-thrown

### 1.0.0.beta5 (2017-11-27)

* Fix #5 Measure for object_id ... not finished

### 1.0.0.beta4 (2017-11-16)

* Fix a bug where nested models are saved at build time in update operations in
  some cases.

### 1.0.0.beta3 (2017-09-20)

* Fixed log subscription

### 1.0.0.beta2 (2017-09-20)

* Added rubygems badge to readme

* Corrected gem summary

### 1.0.0.beta1 (2017-06-19)

* Initial version as extracted from project

* Start of change log
