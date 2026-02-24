[![Unit tests](https://github.com/sitrox/rails_ops/actions/workflows/ruby.yml/badge.svg)](https://github.com/sitrox/rails_ops/actions/workflows/ruby.yml)
[![Rubocop check](https://github.com/sitrox/rails_ops/actions/workflows/rubocop.yml/badge.svg)](https://github.com/sitrox/rails_ops/actions/workflows/rubocop.yml)
[![Gem Version](https://badge.fury.io/rb/rails_ops.svg)](https://badge.fury.io/rb/rails_ops)

# rails_ops

This Gem introduces an additional service layer for Rails: *Operations*. An
operation is in most cases a *business action* or *use case* and may or may not
involve one or multiple models. Rails Ops allows creating more modular
applications by splitting them up into their different operations. Each
operation is specified in a single, testable class.

To achieve this goal, this Gem provides the following building blocks:

- Various operation base classes for creating operations with a consistent
  interface and no boilerplate code.

- A way of abstracting model classes for a specific business action.

## Requirements & Installation

### Requirements

* `rails > 4`

- RailsOps only works with Rails applications, with the following Rails versions being tested in the CI:
  * Rails 6.0.x
  * Rails 6.1.x
  * Rails 7.0.x
  * Rails 7.1.x
  * Rails 7.2.x
  * Rails 8.0.x
- Additionally, the following Ruby versions are covered by our unit tests:
  * 2.7.8
  * 3.0.1
  * 3.1.0
  * 3.2.0
  * 3.3.0
  * 3.4.0
- Please see the [unit test workflow](https://github.com/sitrox/rails_ops/actions/workflows/ruby.yml) for the combinations of the Rails & Ruby versions, as only compatible versions are tested with each other.
- Prior Rails and Ruby versions may be supported but they are not tested in the CI.
- Rails Ops' model operations require ActiveRecord but are database / adapter
  agnostic

### Installation

1. Add the following to your Rails application's `Gemfile`:

   ```ruby
   gem 'rails_ops'
   ```

2. Create an initializer file `config/initializers/rails_ops.rb` with the
   following contents:

   ```ruby
   # Replace this with your authorization backend.
   require 'rails_ops/authorization_backend/can_can_can.rb'

   RailsOps.configure do |config|
     # Replace this with your authorization backend.
     config.authorization_backend = 'RailsOps::AuthorizationBackend::CanCanCan'
   end
   ```

3. Optional: If you want your operations to reside inside of `app/operations`
   and be scoped in the `Operations` namespace, create the directory `app/operations` and add the
   following code inside of the previously created initializer (after the `RailsOps.configure`
   block):

   ```ruby
   # Remove the folder from the autoload paths
   app_operations = "#{Rails.root}/app/operations"
   ActiveSupport::Dependencies.autoload_paths.delete(app_operations)

   # Define the Operations module
   module Operations; end

   # Add the folder to the autoloader, but namespaced
   loader = Rails.autoloaders.main
   loader.push_dir(app_operations, namespace: Operations)

   # Add the folder to the watched directories (for re-loading in development)
   Rails.application.config.watchable_dirs.merge!({
     app_operations => [:rb]
   })
   ```

   Taken from [this github issues comment](https://github.com/rails/rails/issues/40126#issuecomment-816275285).

## Operation Basics

### Placing and Naming Operations

- Operations generally reside in `app/operations` and can be nested using
  various subdirectories. They're all inside of the `Operations` namespace.

- Operations operating on a specific model should generally be namespaced with
  the model's class name. So for instance, the operation `Create` for the `User`
  model should generally live under `app/operations/user/create.rb` and
  therefore should be called `Operations::User::Create`.

- Operations inheriting from other operations should generally be nested within
  their parent operation. See the next section for more details.

- Operation classes should always be named after an *action*, such as `Create`,
  `MoveToPosition` and so on. Do not name an operation something like
  `UserCreator` or `CreateUserOperation`.

#### Heads-up: Correct Namespacing

As explained in the previous section, operations should be namespaced properly.
Operations can either live within a module or within a class. In most cases,
operations are placed in the `Operation` module or rather one of its
sub-modules. If, in some special case, operations are nested, they can reside
inside of another operation class (but not inside of its file) as well.

When declaring an operation within a namespace,

- Determine whether the namespace you're using is a module or a class. Make sure
  you don't accidentally redefine a module as a class or vice-versa.

- If the operation resides within a module, make a module definition on the
  first line and the operation class on the second. Example:

  ```ruby
  module Operations::Frontend::Navigation
    class DetermineActionsForStructureElement < RailsOps::Operation
      ...
    end
  end
  ```

- If the operation resides within a class, use a single-line definition:

  ```ruby
  class Operations::User::Create::FromApi < Operations::User::Create
    ...
  end
  ```

Note that, when defining a namespace of which a segment is already known as a
(model) class, you cannot just use the model classes name to refer to it:

  ```ruby
  module Operations::User
    class Create < RailsOps::Operation
      def perform
        # This DOES NOT work as `User` in this case refers to the module of
        # the same name defined on the first line of code.
        User.create(params)

        # This works as it takes an absolute namespace:
        ::User.create(params)
      end
    end
  end
  ```

### Basic Operations

Every single operation follows a few basic principles:

- They inherit from {RailsOps::Operation}.

- They are called using the `run` or `run!` methods.

- They are parameterized using a `params` hash (and nothing else).

- They define a protected `perform` method which actually executes the
  operation. This is usually overridden in each operation and called exclusively
  by `run` or `run!`.

- They have a *Context*. See the respective chapter for more information.

So, an example of a very simple operation would be:

```ruby
class Operations::PrintHelloWorld < RailsOps::Operation
  def perform
    puts "Hello #{params[:name]}"
  end
end
```

### Running Operations Manually

There are various ways of instantiating and running an operation. The most
basic way is the following:

```ruby
op = Operations::PrintHelloWorld.new(name: 'John Doe')
op.run
```

There is even a shortcut for this:

```ruby
Operations::PrintHelloWorld.run(name: 'John Doe')
```

### Validations, `run` and `run!`

As you have noticed, there are two methods for running operations: `run` and
`run!`. They behave exactly like `save` and `save!` of ActiveRecord: While the
`run!` method raises an exception if there is a validation error, `run` would
just return `false` (or `true` on success). As not every operation deals with
models or ActiveRecord models, `run` does not only catch the
`ActiveRecord::RecordInvalid` exception but also every exception that derives
from {RailsOps::Exceptions::ValidationFailed}.

#### Catching Custom Exceptions in `run`

If you'd like to catch a custom exception if the operation is called using
`run`, you can either derive this exception from
{RailsOps::Exceptions::ValidationFailed} or else override the
`validation_errors` method:

```ruby
class Operations::PrintHelloWorld < RailsOps::Operation
  # Returns an array of exception classes that are considered as validation
  # errors.
  def validation_errors
    super + [SomeCustomException]
  end
end
```

### Returning Data from Operations

All operations have the same call signatures: `run` always returns `true` or
`false` while `run!` always returns the operation instance (which allows easy
chaining). If you need to access data that has been generated / processed /
fetched in the operation, create custom accessor methods:

```ruby
class Operations::GenerateHelloWorld < RailsOps::Operation
  attr_reader :result

  def perform
    @result = "Hello #{params[:name]}"
  end
end

puts Operations::GenerateHelloWorld.run!(name: 'John Doe').result
```

## Params Handling

### Passing Params to Operations

Each single operation can take a `params` hash. Note that it does not have to be
in any relation with `ActionController`'s params - it's just a plain ruby hash
called `params` (in fact, it is a `Object::HashWithIndifferentAcces`, more on
that later).

Params are assigned to the operation via their constructor:

```ruby
Operations::GenerateHelloWorld.new(foo: :bar)
```

If no params are given, an empty params hash will be used. If a
`ActionController::Parameters` object is passed, it will be permitted using
`permit!` and converted into a regular hash.

### Accessing Params

For accessing params within an operation, you can use `params` or `osparams`.
While `params` directly returns the params hash, `osparams` converts them into
an `OpenStruct` first. This allows easy access using the 'dotted notation':

```ruby
def perform
  # Access a param using the `params` method
  params[:foo]

  # Access a param using the `osparams` method
  osparams.foo
end
```

Note that both `params` and `osparams` return independent, deep duplicates of
the original `params` hash to the operation, so the hashes do not correspond.

The hash accessed via `params` is always an `Object::HashWithIndifferentAccess`.

### Validating Params

You're strongly encouraged to perform a validation of the parameters passed to
an operation, as unvalidated params pose a security threat. This can be done in several ways:

- Using a [schemacop](https://github.com/sitrox/schemacop) schema:

  ```ruby
  class Operations::PrintHelloWorld < RailsOps::Operation
    schema3 do
      str! :name
    end

    def perform
      puts "Hello #{params[:name]}"
    end
  end
  ```

  This is the recommended way of performing basic params validation. Please see the next section *Schema best practices* for more information.

  See documentation of the gem `schemacop` for more information on how to
  specify schemata.


- Manually using a *policy* (see chapter *Policies*):

  ```ruby
  class Operations::PrintHelloWorld < RailsOps::Operation
    policy do
      unless osparams.name && osparams.name.is_a?(String)
        fail 'You must supply the "name" argument.'
      end
    end

    def perform
      puts "Hello #{params[:name]}"
    end
  end
  ```

- Using a business model (see chapter *Model Operations*).

### Schema Best Practices

As previously mentioned, using schema from the `schemacop` gem is the recommended way to validate params passed in to an operation. In general, it's recommended to use version 3 of schemacop, i.e. either use `schema3` to specify the schema, or set the default schema version to 3:

```ruby
# config/initializers/rails_ops.rb
RailsOps.configure do |config|
  config.default_schemacop_version = 3
end
```

#### Internal Code

When writing a schema for an operation which is only used internally (e.g. called from another operation, or called from a part of the code where you control the params, e.g. a rake task), it's recommended to specify the types of all items, as this will catch any mismatched data. For example:

```ruby
class Operations::PrintHelloWorldWithId < RailsOps::Operation
    schema3 do
      int! :id
      str! :name
    end

    def perform
      puts "Hello #{params[:name]}, your ID is: #{params[:id]}"
    end
  end
```

#### Called Within Controllers

On the other hand, operations which are called within controllers (e.g. to encapsulate an update operation of a model) should not assume any types, and instead use model validations (if applicable) to validate the correctness of the data. In this case, the schema should only be used to filter the params. As such, it's recommended to use `obj` to specify params which are not strings, as this will allow anything (but only the specified values). An example would be:

```ruby
module Operations::User
  class Update < RailsOps::Operation::Model::Update
    schema3 do
      int! :id
      hsh? :user do
        obj! :age
        str! :first_name
        obj! :is_active
      end
    end
  end
end
```

Validating that `age` is an integer and `is_active` then should be done with a validation in the `User` model, as this will also populate the model errors, which in turn will display the error in the form. If you were to validate the type of the data here, it would raise a `Schemacop::Exceptions::ValidationError` exception, which you would need to handle seperately.

Finally, when additional, obsolete params are supplied, the schema validation would also fail. To have a similar behaviour to the strong params from Rails, which drop non-whitelisted params without raising an exception, you can use the `ignore_obsolete_properties` option. This will simply ignore and drop any params which are not explicitly whitelisted:

```ruby
module Operations::User
  class Update < RailsOps::Operation::Model::Update
    schema3 ignore_obsolete_properties: true do
      int! :id
      hsh? :user do
        obj! :age
        str! :first_name
        obj! :is_active
      end
    end
  end
end
```

### Catching Schema Validation Errors

When an operation is called from a controller (via the `run` or `run!` method) and a schema validation exception occurs, the controller will respond with an empty body and a status code `400` (bad request). This behaviour is enabled by default, but can be disabled with the `rescue_validation_error_in_controller` config option:

```ruby
# config/initializers/rails_ops.rb
RailsOps.configure do |config|
  config.rescue_validation_error_in_controller = false
end
```

Generally, this should be left enabled, as sending invalid data to the controller should not result in an internal server error, but rather in a "client error".

Please note that this behaviour is disabled in development mode, as the full exception messages are useful for debugging purposes.

## Policies

Policies are nothing more than blocks of code that run either at operation
instantiation or before / after execution of the `perform` method and can be
used to check conditions such as params or permissions.

Policies are specified using the static method `policy`, inherited to any
sub-classes and executed in the order they were defined.

```ruby
class Operations::PrintHelloWorld < RailsOps::Operation
  policy do
    puts 'This runs first'
  end

  policy do
    puts 'This runs second'
  end

  def perform
    puts 'This runs third'
    puts 'Oh, and hello world'
  end
end
```

The basic idea of policies is to validate input data (the `params` hash) or
other conditions such as authorizations or locks.

Some checks might still need to be performed directly within the `perform`
method. Use policies as much as possible though to keep things separated.

The return value of the policies is discarded. If a policy needs to fail, raise
an appropriate exception.

### Policy Chains

As mentioned above, policies can be executed at various points in your
operation's lifecycle. This is possible using *policy chains*:

- `:before_attr_assign`

  Policies in this chain run before assigning the attributes to the model. This chain is only run
  in `Model` operations, which at some point call the `assign_attributes` method. This chain is
  the only chain in which the model is in the state *before* the passed in params are assigned.
  If you need to run any code which needs the state of the model from the database (e.g. to run
  custom authentications), this is the correct place.

- `:on_init`

  Policies in this chain run after the operation class is instantiated.

- `:before_perform`

  Policies in this chain run immediately before the `perform` method is called.
  Obviously this is never called if the operation is just instantiated and never
  run. This is the default chain.

- `:before_model_save`

  This only applies to operations deriving from `RailsOps::Operation::Model` and
  its descendants. Policies in this chain run after nested model operations are
  performed immediately before the "main" model is saved.

- `:before_nested_model_ops`

  This only applies to operations deriving from `RailsOps::Operation::Model` and
  its descendants. Policies in this chain run after nested model operations are
  performed before performing any nested model operations.

- `:before_model_validation`

  This only applies to operations deriving from `RailsOps::Operation::Model`
  and its descendants. Policies in this chain run right before
  `model.validate!` is called inside `perform_nested_model_ops!`. This is
  the correct place for attribute cleanup and sanitization — for example,
  nilling out attributes that are irrelevant based on another attribute's
  value (e.g. role-dependent fields after a form reload). At this point
  the model's attributes are already assigned, so you can inspect and
  modify them before validation runs.

- `:after_perform`

  Policies in this chain run immediately after the `perform` method is called.
  Obviously this is never called if the operation is just instantiated and never
  run. Also, this does not run if an exception occurs while performing the
  operation.

The policy chain (default is `:before_perform`) can be specified as the first
argument of the `policy` class method:

```ruby
class MyOp < RailsOps::Operation
  policy :on_init do
    puts 'This is run once the operation has been instantiated.'
  end

  policy do
    puts 'This is run before the operation is performed.'
  end
end
```

The order inside the same policy chain depends on the time when a block was added.
You can prepend an action to a policy chain by setting `:prepend_action` to `true`:

```ruby
class MyOp
  policy :on_init, prepend_action: true do
    puts 'This is run first the operation has been instantiated.'
  end
```

In this case the model is not yet set. That will happen later in the `:on_init` chain.
It is also important to note, that this block is
not guaranteed to be run first in the chain, if multiple blocks have set `:prepend_action` to true.


## Calling Sub-Operations

It is possible and encouraged to call operations within operations if necessary.
As the basic principle is to create one operation per business action, there are
cases where nesting operations can be very beneficial.

Let's say we have an operation `User::Create` that creates a new user. The
operation should also assign the newly created user to a default `Group` after
creation. In this case, we basically have two separate operations that should
not be combined in one. For this case, use sub-operations:

```ruby
class Operations::User::Create < RailsOps::Operation
  def perform
    user = User.create(params)
    run_sub! AssignToGroup, user: user, group: Group.default
  end
end
```

Every operation offers the methods {RailsOps::Mixins::SubOps.run_sub},
{RailsOps::Mixins::SubOps.run_sub!} and {RailsOps::Mixins::SubOps.sub_op}. The
latter one just instantiates and returns a sub operation.

So why don't we just create and call the sub-operation directly? The reason lies
within the context that is automatically adapted and passed to the sub-operation
and enables to maintain the complete call stack and allows to pass on context
information such as the current user.

### A Note on Validations

As always when calling operations, you can decide whether an execution should
raise an exception on validation errors or else just return `false` by using the
bang or non-bang methods.

For nested operations, we must give this fact a little more thought. Consider
the following case:

- Operation *A* is called using `run`.
- Operation *A* calls operation *B* using `run_sub!`.
- Operation *B* throws a validation exception.

In this case, it is now expected that *A* returns non-gracefully, even though
it's called using the non-bang method. The reason is that *A* explicitly used
the bang-method for calling the sub-op.

However, as calling *A* catches any validation errors, it will also catch the
validation errors raised by a sub-operation. For this case, calling `run_sub!`
catches any validation errors and re-throws them as
{RailsOps::Exceptions::SubOpValidationFailed} which is not caught by the
surrounding op.

## Contexts

Most operations make use of generic parameters like the current user or an
authorization ability. Sure this could all be passed using the `params` hash,
but as this would have to be done for every single operation call, it would be
quite cumbersome.

For this reason, Rails Ops provides a feature called *Contexts*. Contexts are
simple instances of {RailsOps::Context} that may or may not be passed to
operations. Contexts can include the following data:

- A user object

  This is meant to be the user performing the operation. In a controller
  context, this usually referred to as `current_user`.

- The session object

  This is the rails `session` object (can be nil).

- An ability object

  This is an ability object (i.e. cancan(can)) which holds the permissions
  currently available. This is used for authorization within an operation.

- The operations chain

  The operations chain contains the call stack of operations. This is
  automatically generated when calling a sub-op or triggering an op using an
  event (see chapter *Events* for more information on that).

- URL options

  Rails uses a hash named `url_options` for generating URLs with correct prefix.
  This information usually comes from a request and is automatically passed to
  the operation context when calling an operation from a controller. This hash
  is used by {RailsOps::Mixins::Routes}.

- View context

  If the operation has been created from within a controller, the property
  `view` includes the current view context. Only use this for frontend
  operations that will always be called from a controller.

- Called via hook

  `called_via_hook` is a boolean indicating whether or not this operation was
  called by a hook (true) or by a regular method call (false). We will introduce
  hooks below.

### Instantiating Contexts

Contexts behave like a traditional model object and can be instantiated in
multiple ways:

```ruby
context = Context.new(user: current_user, params: { foo: bar })

# Another way
context = Context.new
context.user = current_user
```

### Feeding Contexts to Operations

Contexts are assigned to operations via the operation's constructor:

```ruby
my_context = RailsOps::Context.new
op = Operations::PrintHelloWorld.new(my_context, foo: :bar)
```

For your convenience, contexts also provide `run` and `run!` methods:

```ruby
my_context.run Operations::PrintHelloWorld, foo: :bar
```

### Sub-operations

When calling a sub-operation either using the corresponding sub-operation
methods or else using events, a new context is automatically created and
assigned to the sub-operation. This context includes all the data from the
original context. Also, the operations chain is automatically complemented with
the parent operation.

This is called *context spawning* and is performed using the
{RailsOps::Context.spawn} method.

## Hooks

In some cases, certain actions must be hooked in after execution of an
operation. While this can certainly be done with sub-operations, it is not
always desirable as the triggering operation should not always know of the
additional ones it's triggering:

- `Operations::User::Create` creates a user, but also creates a group object
  using `Operations::Group::Create`. *This is an example for sub-ops*.

- `Operations::User::Create` creates a user. Whenever a user is created, another
  part of the application needs to generate a todo for the admin to approve this
  user. *This would be an example for hooks*.

Hooks are pretty simple: Using the file `config/hookup.rb`, you can
specify which operations should be triggered after which operations. These
operations are then automatically triggered after the original operation's
`perform` (in the `run` method).

### Defining Hooks

Hooks are defined in a file named `config/hookup.rb` in your local application.
In development mode, this file is automatically reloaded on each request so
there is no need to restart the application server for this while developing.

Defining hooks is as simple as defining a target operation and one or more
source operations.

```ruby
RailsOps.hookup.draw do
  run 'Operations::Notifications::User::SendWelcomeEmail' do
    on 'Operations::User::Create'
  end

  run 'Operations::Todos::GenerateUserApprovalTodo' do
    on 'Operations::User::Create'
  end

  run 'Operations::Notification::SendTodoNotification' do
    on 'Operations::Todos::GenerateUserApprovalTodo'
  end
end
```

Operations hooks are always performed in the order they are defined.

### Events

Each operation can throw different *events*. The event `:after_run` is
automatically triggered after each operation's execution and should be
sufficient for most cases. However, it is also possible to trigger custom events
in the `perform` method:

```ruby
def perform
  trigger :custom_event_name, { some: :params }
end
```

This can be hooked by specifying the custom event name in your hookup
configuration:

```ruby
on Operations::User::Create, :custom_event_name do
  perform Operations::Notifications::User::SendWelcomeEmail
end
```

In most cases though, situations like these should rather be handled by
explicitly calling a sub-operation.

### Hook Parameters

For each hook that is called, at set of parameters is passed to the respective
operations. When calling events manually (see section *Events*), you can
manually specify the parameters. For the default event `:after_run`, the set of
parameters is defined by the operation method `after_run_trigger_params`. In the
default case, this returns an empty array. Some operation base classes, like for
instance `RailsOps::Operation::Model`, override this method to supply a custom
set of parameters. See your respective base class for more information.

Be advised: It is not usually desirable to provide a very custom param set that
is tailored to one particular target operation. Trigger parameters should be as
generic as possible as specific cases should rather be handled using sub-ops.

Operations can be used to write adapters (*glue* operations) in order to hook
into an operation with incompatible parameters. Create a glue operation that
hooks into the source operation and prepares the params specifically for the
target operation, which is then called using a sub-operation or the hooking
system.

### Check if Called via Hook

You can determine whether your operation has been (directly) called via a hook
using the `called_via_hook` context method:

```ruby
def perform
  puts 'Called via hook' if context.called_via_hook
end
```

Note that this property never propagates, so when calling a sub-operation from
an operation that has been called using a hook, `called_via_hook` of the
sub-operation is set to `false` again.

### Authorization

Operations called via hooks perform normal authorization per default. You can
turn this off by switching off the global option
`config.trigger_hookups_without_authorization`.

## Authorization

Rails Ops offers backend-agnostic authorization using so-called
*authorization backends*.

Authorization basically happens by calling the method `authorize!` (or
`authorize_only!`, more on that later) within an operation. What exactly this
method does depends on the *authorization backend* specified.

### Authorization Backends

Authorization backends are simple classes that supply the method `authorize!`.
This method, besides the operation instance, can take any number of arguments
and is supposed to perform authorization and raise if the authorization failed.

The authorization backend can be configured globally using the
`authorization_backend` configuration setting, which can be set to the name of
your backend class.

Example initializer:

```ruby
RailsOps.configure do |config|
  config.authorization_backend = 'RailsOps::AuthorizationBackends::CanCanCan'
end
```

RailsOps ships with the following backend:

- `RailsOps::AuthorizationBackend::CanCanCan`

  Offers integration of the `cancancan` gem (which is a fork of the `cancan`
  gem).

### Performing Authorization

Authorization is generally performed by calling `authorize!` in an operation.
The arguments, along with the operation instance, are passed on to the
`authorize!` method of your authorization backend. Basically, you can call
`authorize!` anywhere in your operation, but bear in mind that if your
authorization requires certain data (i.e. the `params` hash), your authorization
calls should occur *after* that certain data is available.

```ruby
class MyOp < RailsOps::Operation
  def perform
    authorize! :read, :some_area
  end
end
```

Usually though, authorization, as other pre-conditions, are called within
policies:

```ruby
class MyOp < RailsOps::Operation
  policy do
    authorize! :read, :some_area
  end
end
```

In many cases, you'd like the authorization to run no matter if the operation
ever runs. For this case, use the `:on_init` policy chain:

```ruby
class MyOp < RailsOps::Operation
  policy :on_init do
    authorize! :read, osparams.some_record
  end
end
```

See section *Policy chains* for more information.

### Ensure That Authorization Has Been Performed

As it is a very common programming mistake to mistakenly omit calling
authorization, Rails Ops offers a solution for making sure that authorization
has been called in every operation.

This is done by calling `ensure_authorize_called!` on your operation. This will
raise an exception if no authorization has been performed. This method is
automatically called in `run` or `run!` after the execution of the `perform`
method.

This method only applies if authorization is currently enabled (see next
section), otherwise it does nothing.

It is implemented so that every call to `authorize!` sets an instance variable
of the respective operation to `true`, and `ensure_authorize_called!` checks
this instance variable on calling.

Sometimes you might want to call authorization that should not count for this
check, i.e. some base authorization that needs to be complemented with some
specific authorization code. In these cases, use `authorize_only!`:

```ruby
def perform
  authorize_only! :foo, :bar

  # The following will fail as authorize_only! calls do not count as authorized.
  ensure_authorize_called!
end
```

This method otherwise does exactly the same as `authorize!` (in fact, it's the
underlying method used by it).

### Param Authorization

Using the static operation method `authorize_param`, you can perform additional
authorization checks when specific params are passed to the operation. This
allows you to disallow certain params, i.e. when updating a model and wanting to
restrict the user to certain fields.

When using non-model operations (operations not inheriting from
`RailsOps::Operation::Model` or one of its subclasses), `authorize_param`
requires you to specify an `action` and optional, additional args or a block
that performs custom authorization:

```ruby
class Operations::User::DoSomething < RailsOps::Operation
  schema do
    opt :user do
      opt :name
      opt :group_id
    end
  end

  # Example with passing an action and additional args
  authorize_param %i(user group_id), :update_group_id, :some_subject

  # Example with passing a block
  authorize_param %i(user group_id) do
    # This is executed in the context of the op instance
    fail 'Some message' unless user_has_permission?
  end
```

The first param always provides the path to the param to be checked for
existence. Note that this only works with nested hash structures, but not with
arrays and other objects. The first level of the `params` hash is always using
indifferent access, so it does not matter whether you pass a symbol or a string
as the first path segment. For additional path segments, it needs to match the
actual type that is used as hash key. For example: `[:user, 'group_id']`.

For model operations, you only need to pass a `path` and an `action` if you want
to perform authorization on your model:

```ruby
class Operations::User::Create < RailsOps::Operation::Model::Create
  schema do
    opt :user do
      opt :name
      opt :group_id
    end
  end

  authorize_param %i(user group_id), :assign_group_id
```

### Disabling Authorization

Sometimes you don't want a specific operation to perform authorization, or you
don't want to perform any authorization at all.

For this reason, Rails Ops allows you to disable authorization globally, per
operation or per operation call (i.e. an operation should generally perform
authorization, but not in a specific case). If authorization is disabled, all
calls to `authorize!` won't have any effect and will never fail. Also, it is not
ensured that authorization has been performed as it would always fail (see
previous section).

Rails Ops offers multiple ways of disabling authorization:

- By not configuring any authorization backend.

- By calling the class method `without_authorization`:

  ```ruby
  class MyOp < RailsOps::Operation
    without_authorization
  end
  ```

  If the operation is invoked using controller integration, this also disables
  the controller-side check that makes sure an authorization method is called.

  This does not disable authorization for any sub operations. See the next
  section for information on how to disable sub operation authorization.

- By invoking one or more operations in a `RailsOps.without_authorization`
  block:

  ```ruby
  RailsOps.without_authorization do
    # Authorization will be disabled even if `SomeOperation` itself would
    # otherwise perform authorization.
    SomeOperation.run
  end
  ```

  Within operations, you can also use the instance method
  `without_authorization` which does the same thing as the global one (it is
  just a shortcut and can therefore be used interchangeably):

  ```ruby
  class MyOp < RailsOps::Operation
    def perform
      without_authorization do
        run_sub! SomeOtherOperation
      end
    end
  end
  ```

  Note that when calling `without_authorization` this does not only apply to
  other operations called, but also to the operation you're currently in:

  ```ruby
  class MyOp < RailsOps::Operation
    def perform
      without_authorization do
        # The following line does nothing, as authorization is currently
        # disabled.
        authorize! :read, :some_area
      end
    end
  end
  ```

  However, please note that the block form of `authorize_param` is still executed,
  as there might be code in the block that does not rely on the authorization
  backend:

  ```ruby
  class MyOp < RailsOps::Operation
    def perform
      without_authorization

      authorize_param %i[user group_id] do
        # This block will be called
        fail if ENV['GROUP_ID'].blank?
      end
    end
  end
  ```

  If you want to skip the block, use `authorization_enabled?` to
  check whether the authorization is enabled:

  ```ruby
  class MyOp < RailsOps::Operation
    def perform
      without_authorization

      authorize_param %i[user group_id] do
        next unless authorization_enabled?

        # Do authorization calls
      end
    end
  end
  ```


## Model Operations

One of the key features of RailsOps is model operations. RailsOps provides
multiple operation base classes which allow convenient manipulation of active
record models.

All of the model operation classes, including more specialized base classes,
inherit from {RailsOps::Operation::Model} (which in turn inherits from
{RailsOps::Operation} as every operation base class).

The key principle behind these model classes is to associate *one model class*
and *one model instance* with a particular operation.

### Setting a Model Class

Using the static method `model`, you can assign a model class that is used in
the scope of this operation.

```ruby
class SomeOperation < RailsOps::Operation::Model
  model User
end
```

You can also directly extend this class by providing a block. If given, this
will automatically create a new, anonymous class that inherits from the given
base class and run the given block in the static context of this class:

```ruby
class SomeOperation < RailsOps::Operation::Model
  model User do
    # This code only runs in a dynamically created subclass of `User` and does
    # not affect the original model class.
    validates :name, presence: true
  end
end
```

You do not even have to specify a base class. In this case, the class returned
by the static method `default_model_class` (default: {ActiveType::Object}) will
be used as base class:

```ruby
class SomeOperation < RailsOps::Operation::Model
  model do
    # See ActiveType documentation for more information on virtual attributes.
    attribute :name
  end
end
```

### Obtaining a Model Instance

Model instances can be obtained using the *instance* method `model`, which is
not to be confused with the *class* method of the same name. Other than the
class method, the instance method instantiates and returns a model object with
the type / base class specified using the `model` class method:

```ruby
class SomeOperation < RailsOps::Operation::Model
  model User

  def perform
    # This returns an instance of the 'User' class. To be precise: This example
    # does not work out-of-the-box as this base class is abstract and does not
    # implement the `build_model` method. But more on that later.
    model
  end
end
```

The instance method `model` only instantiates a model once and then caches it in
the instance variable `@model`. Therefore, you can call `model` multiple times
and always get back the same instance.

If no cached instance is found, one is built using the instance method
`build_model`. Note that this method is not provided by the `Model` base class
but only implemented in its subclasses. You can implement and override this
method to your liking though.

### Loading Models

Using the base operation class {RailsOps::Operation::Model::Load}, a model can
be loaded. This is done by implementing the `build_model` mentioned above. In
this particular case, the `find` method of the statically assigned model class
is used in conjunction with an ID extracted from the operation's params.

```ruby
class Operations::User::Load < RailsOps::Operation::Model::Load
  model User
end

# The operation does not have to be performed to access the model instance.
op = Operations::User::Load.new(id: 5)
op.model.id # => 5
```

Note that this base class is a bit of a special case: It does not provide an
implementation of the `perform` method and does not need to be run at all in
order to load a model (in fact, it cannot be run unless you override the
`perform` method). This is very useful when, for example, displaying a form
based on a model instance without actually performing any particular action such
as updating a model.

#### Specifying ID Field

Per default, the model instance is looked up using the field `id` and the ID
obtained from the method params using `params[:id]`. However, you can customize
this field name by overriding the method `model_id_field`:

```ruby
class Operations::User::Load < RailsOps::Operation::Model::Load
  model User

  def model_id_field
    :some_other_id_field
  end
end
```

#### Customizing the Lookup Relation

By default, `Load` operations look up the model using the relation returned
by `self.class.model` (i.e. the model class itself). If you need to use a
custom relation — for example to apply a scope, join additional tables, or
restrict visibility — you can override the `protected` method
`find_model_relation`.

Since `Update` and `Destroy` operations inherit from `Load`, this hook is
available in all of them. For example, you can scope an `Update` operation
so that it only finds records belonging to the current user's organization:

```ruby
class Operations::User::Update < RailsOps::Operation::Model::Update
  model User

  protected

  def find_model_relation
    User.where(organization: context.user.organization)
  end
end
```

The returned object must be an ActiveRecord relation (or the model class
itself, which acts as one). Locking and eager loading via `model_includes`
are applied on top of whatever relation this method returns.

#### Locking

In most cases when you load a model, you might want to lock the corresponding
database record. RailsOps is configured to automatically perform this locking
at time of loading. However, you can override the default behavior using
the option {RailsOps.config.lock_models_at_build}.

This behavior can also be overwritten per operation using the
`lock_model_at_build` class method:

```ruby
class Operations::User::Update < RailsOps::Operation::Model::Update
  model ::User
  lock_model_at_build false # Takes `true` if no argument is passed
end
```

Please note that for performance reasons, the `Load` operation (and any
operations inheriting from it) use a shared lock, i.e. it issues
an `LOCK IN SHARE MODE` / `FOR SHARE` statement. The `Update` and `Destroy`
operations (as well as operations inheriting from it) however use the default
`lock` method of ActiveRecord, which will issue an exclusive lock.

If you want to change the mode, you can use the `lock_mode` DSL method, which
has two possible modes:

* `:shared` for the shared lock mode
* `:exclusive` for the exclusive lock mode

For example, if you have an operation loading a record which you'd want to
lock exclusively, you'd need to write the following:

```ruby
class Operations::User::Update < RailsOps::Operation::Model::Load
  model ::User
  lock_mode :exclusive
end
```

One caveat is that shared locking is only supported for MySQL (MariaDB),
PostgreSQL and Oracle DB databases, any other database will always use an
exclusive lock.

You can also dynamically enable or disable locking by creating an instance
method `lock_model_at_build?`:

```ruby
class Operations::User::Update < RailsOps::Operation::Model::Load
  model ::User

  protected

  def lock_model_at_build?
    # Example: Lock based on a parameter
    osparams.lock
  end
end
```

### Creating Models

For creating models, you can use the base class
{RailsOps::Operation::Model::Create}.

This class mainly provides an implementation of the methods `build_model` and
`perform`.

The `build_model` method builds a new record using the operation's parameters.
See section *Parameter extraction for create and update* for more information on
that.

The `perform` method saves the record using `save!`.

```ruby
class Operations::User::Create < RailsOps::Operation::Model::Create
  schema do
    req :user do
      opt :first_name
      opt :last_name
    end
  end

  model ::User
end
```

As this base class is very minimalistic, it is recommended to fully read and
comprehend its source code.

#### Overriding the Perform Method

While in many cases there is no need for overriding the `perform` method, this
can be useful i.e. when assigning or altering properties manually:


```ruby
def perform
  model.some_value = 42
  model.first_name.upcase!
  super # Saves the record
end
```

### Updating Models

For updating models, you can use the base class
{RailsOps::Operation::Model::Update} which is an extension of the `Load` base
class.

This class mainly provides an implementation of the methods `build_model` and
`perform`.

The `build_model` method updates a record using the operation's parameters. See
section *Parameter extraction for create and update* for more information on
that.

The `perform` method saves the record using `save!`.

```ruby
class Operations::User::Update < RailsOps::Operation::Model::Update
  schema do
    req :id
    req :user do
      opt :first_name
      opt :last_name
    end
  end

  model ::User
end
```

As this base class is very minimalistic, it is recommended to fully read and
comprehend its source code.

As with `Create` operations, the `perform` method can be overwritten at your
liking.

### Destroying Models

For destroying models, you can use the base class
{RailsOps::Operation::Model::Destroy} which is an extension of the `Load` base
class.

This class mainly provides an implementation of the method `perform`, which
destroys the model using its `destroy!` method.

```ruby
class Operations::User::Destroy < RailsOps::Operation::Model::Destroy
  schema do
    req :id
  end

  model ::User
end
```

As this base class is very minimalistic, it is recommended to fully read and
comprehend its source code.

### Including Associated Records

Normally, when inheriting from `RailsOps::Operation::Model::Load` (as well as from the
`Update` and the `Destroy` operations respectively), RailsOps only loads the instance
of the model specified by the `id` parameter. In some cases, you'd want to eagerly load
associations of the model, e.g. when you need to access associated records.

For this, RailsOps provides the `model_includes` DSL method, with which you can
pass-in associations to eager load (the value will simply be passed on to an `includes`
call). See the following code snipped for an example:

```ruby
class Operations::User::Load < RailsOps::Operation::Model::Load
  schema3 do
    int! :id, cast_str: true
  end

  model ::User

  # This will result in RailsOps eagerly loading the `posts`
  # association, as well as the comments and authors of the
  # comments.
  # The call that RailsOps will create is:
  # User.includes(posts: { comments: :author }).find_by(id: params[:id])
  model_includes posts: { comments: :author }
end
```

### Parameter Extraction for Create and Update

As mentioned before, the `Create` and `Update` base classes provide an
implementation of `build_model` that assigns parameters to a model.

The attributes are determined by the operation instance method
`extract_attributes_from_params` - the name being self-explaining. See its
source code for implementation details.

### Model Authorization

While you can use the standard `authorize!` method (see chapter *Authorization*)
for authorizing models, RailsOps provides a more convenient integration.

#### Basic Authorization

Model authorization can be performed via the operation instance methods
`authorize_model!` and `authorize_model_with_authorize_only!` (see chapter
*Authorization* for more information on the difference between these two).

These two methods provide a simple wrapper around `authorize!` and
`authorize_only!` that casts the given model class or instance to an active
record object. This is necessary if the given model class or instance is a
(possibly anonymous) extension of an active record class for certain
authorization backends to work. Therefore, use the specific model authorization
methods instead of the basic authorization methods for authorizing models.

If no model is given, the model authorization methods automatically obtain the
model from the instance method `model`.

#### Automatic Authorization

All model operation classes provide the operation instance method
`model_authorization` which is automatically run at model instantiation (this is
done using an `:on_init` policy). The purpose of this method is to perform an
authorization check based on this model.

While you can override this method to perform custom authorization, RailsOps
provides a base implementation. Using the class method
`model_authorization_action` (or `load_model_authorization` for operations
inheriting from `RailsOps::Operation::Model::Load`), you can specify an action
verb that is used for authorizing your model.

```ruby
class Operations::User::Load < RailsOps::Operation::Model::Load
  model User

  # This automatically calls `authorize_model! :read` after operation
  # instantiation.
  load_model_authorization :read
end
```

Another example for an update operation:

```ruby
class Operations::User::Update < RailsOps::Operation::Model::Update
  model User

  # This automatically calls `authorize_model! :read` after operation
  # instantiation.
  load_model_authorization :read

  # This automatically calls `authorize_model! :update` after operation
  # instantiation.
  model_authorization :update
end
```

Note that using the different model base classes, this is already set to a
sensible default. See the respective class' source code for details.

#### Lazy Model Update Authorization

*Please note that using lazy model update authorization is deprecated any may
be removed in a future release. See the changelog for instructions on how to
adapt your application.*

In case of operations inheriting from `RailsOps::Operation::Model::Update`, you
can specify the `model_authorization_action` to be `lazy`, meaning that it will
only be checked when *performing* the operation, but not on initialization. This
can be useful for displaying readonly forms to users which have read-permissions
only:

```ruby
class Operations::User::Update < RailsOps::Operation::Model::Update
  model User

  # This automatically calls `authorize_model! :read`. Because it is set to be
  # `lazy`, the authorization will only run when the operation is actually
  # *performed*, and not already at instantiation.
  model_authorization_action :update, lazy: true
end
```

### Model Nesting

Using active record, multiple nested models can be saved at once by using
`accepts_nested_attributes_for`. While this is generally supported by RailsOps,
you may want to consider saving nested models using their own operation.

For this case, RailsOps' create and update model operations provide the method
`nest_model_op`.

```ruby
class Operations::User::Create < RailsOps::Operation::Model::Create
  schema do
    opt :user do
      opt :name
      opt :group_attributes
    end
  end

  model ::User
  nest_model_op :group, Operations::Group::Create
end

class Operations::Group::Create < RailsOps::Operation::Model::Create
  schema :group do
    opt :name
  end

  model ::Group
end
```

In this example, the parent operation `Operations::User::Create` automatically
instantiates a `Group::Create` operation and passes all the parameters to it
that the parent operation received under `group_attributes`. The group is saved
first. If this is successful, the user is saved.

Note that this feature only works with `belongs_to` associations with `autosave`
set to `false` and is not compatible with `accepts_nested_attributes_for`:

```ruby
class User
  belongs_to :group, autosave: false
end
```

#### Param Key

When nesting a model operation, the sub operation is called automatically by
RailsOps. For this purpose, it needs to know which `param_key` to use for
calling the sub operation, e.g. `user: { name: 'Jane Doe' }`. Normally, this is
derived by calling `<sub-op-model-class>.model_name.param_key`. If your
operation for some reason expects a different param key, you can specify it
using the option `param_key`, e.g.:

```ruby
# Operation Operations::Group::Create will receive the following params:
#   { my_custom_key: { ... } }
nest_model_op :group, Operations::Group::Create, param_key: :my_custom_key
```

#### Custom Parameters

In the above examples, all `group_attributes` are automatically passed to the
sub operation. To customize this further, provide a block to the `nest_model_op`
method:

```ruby
nest_model_op :group, Operations::Group::Create do |params|
  params.merge(custom_override: :some_value)
end
```

This block receives the params hash as it would be passed to the sub operation
and allows to modify it. The block's return value is then passed to the
sub-operation. Do not change the params inplace but instead return a new hash.

### Single-Table Inheritance

Model operations also support STI models (Single Table Inheritance). However,
there is the caveat that if you do extend your model in the operation (e.g.
`model Animal do { ... }`), RailsOps automatically creates an anonymous subclass
of the given class (e.g. `Animal`). Operations will always load / create models
that are instances of this anonymous class.

Consider the following operation:

```ruby
class Animal < ApplicationRecord; end
class Bird < Animal; end
class Mouse < Animal; end

class LoadAnimal < RailsOps::Operation::Model::Load
  model Animal do
    # Something
  end
end

bird = Bird.create
op = LoadAnimal.new(id: bird.id)

bird.class        # => Bird (extending Animal)
op.model.class    # => Anonymous class extending Animal, not Bird
```

## Record Extension and Virtual Records

RailsOps provides powerful features for extending ActiveRecord models and
creating virtual records without affecting your actual model classes. This is
achieved through the use of ActiveType and anonymous class generation.

### Virtual Models

Virtual models are non-persisted models that behave like ActiveRecord models
but exist only in memory. They're useful for:

- Form objects that don't map directly to database tables
- Temporary data structures for complex operations
- Aggregating data from multiple sources

RailsOps provides `RailsOps::VirtualModel` which extends `ActiveType::Object`:

```ruby
class Operations::Contact::Create < RailsOps::Operation::Model::Create
  model do
    # Virtual attributes
    attribute :full_name, :string
    attribute :email, :string
    attribute :message, :text
    attribute :newsletter_opt_in, :boolean, default: false

    # Validations work just like regular models
    validates :full_name, :email, :message, presence: true
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  end

  def perform
    # Process the virtual model data
    ContactMailer.contact_form(
      name: model.full_name,
      email: model.email,
      message: model.message
    ).deliver_later

    # Optionally subscribe to newsletter
    if model.newsletter_opt_in
      NewsletterService.subscribe(model.email)
    end
  end
end
```

### Model Extension

When you specify a model with a block in an operation, RailsOps creates an
anonymous subclass that extends your model without modifying the original:

```ruby
class Operations::User::Import < RailsOps::Operation::Model::Create
  model User do
    # These changes only apply within this operation
    attribute :import_source, :string
    attribute :skip_notifications, :boolean, default: false

    validates :import_source, presence: true

    # Override methods
    def name=(value)
      super(value.strip.titleize)
    end

    # Add callbacks specific to this operation
    before_save :normalize_phone_number

    private

    def normalize_phone_number
      self.phone = PhoneNumberService.normalize(phone) if phone.present?
    end
  end

  def perform
    model.imported_at = Time.current
    super

    unless model.skip_notifications
      UserMailer.welcome(model).deliver_later
    end
  end
end
```

### Virtual Attributes

Virtual attributes allow you to add non-persisted attributes to your models
that behave like regular attributes:

```ruby
class Operations::Order::Checkout < RailsOps::Operation::Model::Update
  model Order do
    # Virtual attributes for checkout process
    attribute :card_number, :string
    attribute :card_cvv, :string
    attribute :card_exp_month, :integer
    attribute :card_exp_year, :integer
    attribute :save_card, :boolean, default: false

    # Validations for virtual attributes
    validates :card_number, presence: true, length: { is: 16 }
    validates :card_cvv, presence: true, length: { in: 3..4 }
    validates :card_exp_month, inclusion: { in: 1..12 }
    validates :card_exp_year, numericality: {
      greater_than_or_equal_to: Date.current.year
    }

    # Virtual attribute for computed values
    attribute :total_with_tax, :decimal

    before_validation :calculate_total_with_tax

    private

    def calculate_total_with_tax
      self.total_with_tax = total * (1 + tax_rate)
    end
  end

  def perform
    # Process payment with virtual attributes
    payment_result = PaymentGateway.charge(
      amount: model.total_with_tax,
      card_number: model.card_number,
      cvv: model.card_cvv,
      exp_month: model.card_exp_month,
      exp_year: model.card_exp_year
    )

    if payment_result.success?
      model.payment_id = payment_result.transaction_id
      model.paid_at = Time.current
      super # Save the order

      # Optionally save card for future use
      if model.save_card
        CreatePaymentMethod.run!(
          user: model.user,
          token: payment_result.card_token
        )
      end
    else
      fail PaymentError, payment_result.error_message
    end
  end
end
```

### Combining Real and Virtual Models

You can create operations that work with both persisted and virtual data:

```ruby
class Operations::Report::Generate < RailsOps::Operation::Model
  model do
    attribute :start_date, :date
    attribute :end_date, :date
    attribute :include_archived, :boolean, default: false
    attribute :format, :string, default: 'pdf'

    validates :start_date, :end_date, presence: true
    validate :end_date_after_start_date

    private

    def end_date_after_start_date
      return unless start_date && end_date
      errors.add(:end_date, 'must be after start date') if end_date < start_date
    end
  end

  def perform
    scope = Order.where(created_at: model.start_date..model.end_date)
    scope = scope.includes(:archived) if model.include_archived

    report_data = ReportBuilder.new(scope).generate

    case model.format
    when 'pdf'
      ReportPdfGenerator.new(report_data).to_pdf
    when 'csv'
      ReportCsvGenerator.new(report_data).to_csv
    else
      report_data
    end
  end
end
```

## Transactions

When working with database operations, it's crucial to ensure data consistency
using transactions, especially when multiple models are involved.

### Transaction Behavior in Model Operations

It's important to understand that RailsOps model operations do NOT automatically
start any transactions.

To ensure all operations succeed or fail together, you must explicitly wrap them
in a transaction:

```ruby
class Operations::Order::Process < RailsOps::Operation::Model::Update
  def perform
    ActiveRecord::Base.transaction do
      model.status = 'processing'
      model.processed_at = Time.current
      super # Saves the order

      # Now if this fails, everything is rolled back
      OrderItem.where(order: model).update_all(status: 'processing')
      InventoryService.reserve_items(model.items)
    end
  end
end
```

Typically though, transactions are opened on a higher level and outside of
operations, e.g. in controller methods.

### Rollback on Exception

When using `run` (without bang), validation errors are caught and may not cause
transaction rollback. The `with_rollback_on_exception` helper ensures that
exceptions within its block are re-raised as `RollbackRequired`, which will
cause a rollback even when using `run`:

```ruby
class Operations::User::ComplexUpdate < RailsOps::Operation::Model::Update
  def perform
    ActiveRecord::Base.transaction do
      super # Saves the user

      # Without with_rollback_on_exception, validation errors here won't
      # roll back the transaction when the operation is called with run
      with_rollback_on_exception do
        model.profile.bio = params[:bio]
        model.profile.save! # If this fails, transaction is rolled back

        model.settings.notifications = params[:notifications]
        model.settings.save! # If this fails, transaction is rolled back
      end
    end
  end
end

class UsersController < ApplicationController
  def update
    ActiveRecord::Base.transaction do
      if run Operations::User::ComplexUpdate
        render json: { status: :success }
      else
        render json: { status: :validation_error }
      end
    end
  end
end
```

**Important**: `with_rollback_on_exception` only works within an existing
transaction. It doesn't create a transaction - it just ensures exceptions
cause rollback:

```ruby
class Operations::Order::Process < RailsOps::Operation::Model::Update
  def perform
    # PROBLEMATIC: Each save creates its own transaction
    super # Order is saved and committed in its own transaction

    with_rollback_on_exception do
      model.line_items.each { |item| item.update!(status: 'processed') }
    end
  end
end

# CORRECT: Wrap in a transaction
class Operations::Order::Process < RailsOps::Operation::Model::Update
  def perform
    ActiveRecord::Base.transaction do
      super # Order is saved

      with_rollback_on_exception do
        model.line_items.each { |item| item.update!(status: 'processed') }
      end
    end
  end
end
```

### After Commit Callbacks

When no explicit transaction is used, each `save!` opens and commits its own
transaction. You can use Rails' after_commit callbacks in your model
extensions for actions that should only run after successful database commits:

```ruby
# Using after_commit callbacks in model extension
class Operations::User::Create < RailsOps::Operation::Model::Create
  model User do
    after_commit :send_notifications, on: :create

    private

    def send_notifications
      UserMailer.welcome(self).deliver_later
      CrmSyncJob.perform_later(self)
    end
  end
end

# Or handle it manually after the operation
class Operations::Order::Complete < RailsOps::Operation::Model::Update
  def perform
    ActiveRecord::Base.transaction do
      model.status = 'completed'
      model.completed_at = Time.current
      super
    end

    # This runs after the transaction commits successfully
    # If there was an exception, we never get here
    OrderMailer.completed(model).deliver_later
  end
end
```

**Note**: Be careful with after_commit callbacks when using transactions.
They fire after each transaction commits, not after all nested transactions
complete.

### Important Notes on Transactions

1. **Validation Errors**: When using `run` (without bang), validation errors
   are caught and won't roll back the transaction. Use `run!` for
   sub-operations to ensure transaction rollback on validation errors.

2. **External Services**: Be careful when calling external services within
   transactions. Long-running external calls can cause database locks:

   ```ruby
   def perform
     ActiveRecord::Base.transaction do
       model.save!

       # DON'T: This could lock the database for a long time
       # ExternalApi.slow_request(model)
     end

     # DO: Call external services after the transaction
     ExternalApi.slow_request(model)
   end
   ```

3. **Nested Transactions**: Rails uses savepoints for nested transactions,
   which are fully supported by RailsOps operations.

## Controller Integration

While RailsOps certainly does not have to be used from a controller, it
provides a mixin which extends controller classes with functionality that lets
you easily instantiate and run operations.

### Installing

Controller integration is designed to be non-intrusive and therefore has to be
installed manually. Add the following inclusion to the controllers in question
(usually the `ApplicationController` base class):

```ruby
class ApplicationController
  include RailsOps::ControllerMixin
end
```

### Basic Usage

The basic concept behind controller integration is to instantiate and
potentially run a single operation per request. Most of this guide refers to
this particular use case. See section *Multiple operations per request* for more
advanced solutions.

The following example shows the simplest way of setting and running an
operation:

```ruby
class SomeController < ApplicationController
  def some_action
    run! Operations::SomeOperation
  end
end
```

### Separating Instantiation and Execution

In the previous example, we instantiated and ran an operation in a single
statement. While this might be feasible for some "fire-and-forget" controller
actions, you might want to separate instantiation from actually running an
operation.

For this reason, RailsOps' controller integration is designed to always use
a two-step process: First the operation is instantiated and assigned to the
controller instance variable `@op`, and then it's possibly executed.

In the following example, we do exactly the same thing as in the previous one,
but with separate instantiation and execution:

```ruby
class SomeController < ApplicationController
  def some_action
    # The following line instantiates the given operation and assigns the
    # instance to `@op`.
    op Operations::SomeOperation

    # The following line runs the operation previously set using `op` using
    # the operations `run!` method. Note that `run` is available as well.
    run!
  end
end
```

The methods `run` and `run!` always require you to previously instantiate an
operation using the `op` method.

This can be particularly useful for "combined" controller methods that either
display a form or submit, i.e. based on the HTTP method used.

```ruby
def update_username
  # As above operation extends RailsOps::Model, we can already access op.model
  # (i.e. in a form) without ever running the operation. Therefore, we
  # instantiate the operation even if it is a GET request.
  op Operations::User::UpdateUsername

  # In this example, the operation is only run on POST requests.
  if request.post? && run
    redirect_to users_path
  end
end
```

### Checking for Operations

Using the method `op?`, you can check whether an operation has already been
instantiated (using `op`).

### Model Shortcut

RailsOps conveniently provides you with a `model` instance method, which is a
shortcut for `op.model`. This is particularly useful since this is available as
a view helper method as well, see next section.

You can check whether a model is available by using the `model?` method, which
is available in both controllers and views.

### View Helper Methods

The following controller methods are automatically provided as helper methods
which can be used in views:

- `op`
- `model`
- `op?`

It is very common to use `model` for your forms:

```
= form_for model do |f|
  - # Form code goes here
```

### Parameters

As you've probably noticed in previous examples, we did not provide any
parameters to the operation.

Per default, the `params` hash is automatically provided to the operation at
instantiation. To be more precise: The params hash is filtered not to include
certain fields (see {RailsOps::ControllerMixin::EXCEPT_PARAMS}) that are most
commonly not used by operations (e.g. the `authenticity_token`).

This is achieved using the private `op_params` method. Overwrite it to your
needs if you have to adapt it for the whole controller.

Alternatively, you can pass entirely custom params to an operation via the `op`
method:

```ruby
op SomeOperation, some_param: 'some_value'
```

You can also combine these two approaches:

```ruby
# This example takes the pre-filtered op_params hash and applies another, custom
# filter before passing it to the operation.
op SomeOperation, some_param: op_params.slice(:some_param, :some_other_param)
```

### Authorization Ensuring

For security reasons, RailsOps automatically checks after each action whether
authorization has been performed. This is to avoid serving an action's response
without ever authorizing.

The check is run in the `after_action` named
`ensure_operation_authorize_called!` and only applies if an operation class has
been set.

Note that this check also doesn't apply if the corresponding operation uses
`without_authorization` (see section *Disabling authorization* for more
information on this).

You can disable authorization ensuring by setting the global config option
`config.ensure_authorize_called = false`.

### Context

When using the `op` method to instantiate an operation, a context is
automatically created. The following fields are set automatically:

- `params` (as described in subsection *Parameters*)
- `user` (uses `current_user` controller method if available, otherwise `nil`)
- `ability` (uses `current_ability` controller method if available, otherwise `nil`)
- `session` (uses the `session` controller method)
- `url_options` (uses the `url_options` controller method)

### Multiple Operations per Request

RailsOps does not currently support calling multiple operations in a single
controller action out-of-the-box. You need to instantiate and run it manually.

Another approach is to create a parent operation which calls multiple
sub-operations, see section *Calling sub-operations* for more information.

## Operation Inheritance

## Generators

RailsOps features a generator to easily create a structure for common CRUD-style
constructs. The generator creates the CRUD operations, some empty view files, a
controller and adds an entry in the routing file.

This is e.g. useful when adding a new model to an application, as the basic structure
is usually rather similar.

### Usage

Run the generator using the `operation` generator, specifying the name of the
operation class:

```ruby
rails g operation User
```

This will generate the following operations:

* `app/operations/user/load.rb`
* `app/operations/user/create.rb`
* `app/operations/user/update.rb`
* `app/operations/user/destroy.rb`

as well as the controller `app/controllers/users_controller.rb` and the following
empty view files:

* `app/views/users/index.html.haml`
* `app/views/users/show.html.haml`
* `app/views/users/new.html.haml`
* `app/views/users/edit.html.haml`

It will also add the entry `resources :users` to the `config/routes.rb` file.

If you want to skip the controller, the views or the routes, you can do so using the
flags:

* `--skip-controller`
* `--skip-routes`
* `--skip-views`

Or if you want to skip them all: `--only-operations`.

If you want to skip a certain action, you can do so using the flags:
* `--skip-index`
* `--skip-show`
* `--skip-create`
* `--skip-update`
* `--skip-destroy`

This will skip the creation of the respective route, controller action, view file and the operation itself.
For `--skip-create`, the `new` action will also be skipped and for `--skip-update`, the `edit` action will be skipped respectively.

You can also add a module as a namespace, all generated files will be put in
the proper subfolders and modules by using the `--module` option.

As an example:

```ruby
rails g operation User --module Admin
```

This will generate the following operations:

* `app/operations/admin/user/load.rb`
* `app/operations/admin/user/create.rb`
* `app/operations/admin/user/update.rb`
* `app/operations/admin/user/destroy.rb`

These operations will be namespaced in the `Admin` module, e.g. `app/operations/admin/user/load.rb` will define `Operations::Admin::User::Load`.

It will also generate the controller `app/controllers/admin/users_controller.rb` and the following
empty view files:

* `app/views/admin/users/index.html.haml`
* `app/views/admin/users/show.html.haml`
* `app/views/admin/users/new.html.haml`
* `app/views/admin/users/edit.html.haml`

Both lower- and uppercase will generate the same files (i.e. `--module Admin` and `--module admin` are equal).

You can even nest the generated files deeper, `--module Admin::Foo` and `--module admin/foo` will both work.

Of course, at this point, the operations will need some adaptions, especially the
[parameter schemas](#validating-params), and the controllers need the logic for the
success and failure cases, as this depends on your application.

## Lazy Load Hooks

RailsOps provides the following [Rails Lazy Load
Hooks](https://api.rubyonrails.org/v7.1.3.4/classes/ActiveSupport/LazyLoadHooks.html):

- `rails_ops_op_model_create` for `RailsOps::Operation::Model::Create`
- `rails_ops_op_model_destroy` for `RailsOps::Operation::Model::Destroy`
- `rails_ops_op_model_load` for `RailsOps::Operation::Model::Load`
- `rails_ops_op_model_update` for `RailsOps::Operation::Model::Update`
- `rails_ops_op` for `RailsOps::Operation`

Example usage:

```ruby
ActiveSupport.on_load(:rails_ops_op_model_create) { include MyMixin }
```

## Caveats

### Eager Loading in Development Mode

Eager loading operation classes containing models with nested models or
operations can be very slow in performance. In production mode, the same process
is very fast and not an issue at all. To work around this problem, make sure you
exclude your operation classes (i.e. `app/operations`) in your
`config.eager_load_paths` of `development.rb`. Make sure not to touch this
setting in production mode though.

## Contributors

This gem is heavily inspired by the [trailblazer](http://trailblazer.to/) gem
which provides a wonderful, high-level architecture for Rails – beyond just
operations. Be sure to check this out when trying to decide on an alternative
Rails architecture.

## Copyright

Copyright © 2017 - 2026 Sitrox. See `LICENSE` for further details.
