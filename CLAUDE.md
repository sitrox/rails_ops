# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build and test
- `bundle exec rake test` - Run the complete test suite
- `bundle exec rake test TEST=test/unit/path/to/test.rb` - Run a specific test file
- `bundle exec rake test TEST=test/unit/path/to/test.rb TESTOPTS="--name=test_name"` - Run a single test
- `bundle exec rubocop` - Run code linting with RuboCop
- `bundle exec rubocop -a` - Auto-fix RuboCop violations where possible
- `bundle install` - Install dependencies
- `bundle exec appraisal install` - Install dependencies for all Rails versions
- `bundle exec appraisal rails_X.Y rake test` - Test against specific Rails version (e.g., rails_7.1)

## Architecture Overview

RailsOps is a service layer gem for Rails applications that implements the Operation pattern. It provides a consistent way to encapsulate business logic in testable, reusable classes.

### Core Components

1. **Operations** (`lib/rails_ops/operation.rb`)
   - Base class for all operations
   - Handles params validation via Schemacop
   - Includes authorization, policies, and sub-operations
   - Key methods: `run`, `run!`, `perform`

2. **Model Operations** (`lib/rails_ops/operation/model/`)
   - `Load` - Loads a model by ID with optional locking
   - `Create` - Creates new model instances
   - `Update` - Updates existing models
   - `Destroy` - Destroys models
   - Supports nested model operations and STI

3. **Context** (`lib/rails_ops/context.rb`)
   - Carries request-specific data (user, session, ability, etc.)
   - Automatically passed to sub-operations
   - Used for authorization and access control

4. **Controller Integration** (`lib/rails_ops/controller_mixin.rb`)
   - Provides `op` and `run`/`run!` helpers
   - Automatic context creation
   - Authorization checking in after_action

5. **Authorization** (`lib/rails_ops/mixins/authorization.rb`)
   - Backend-agnostic authorization
   - Supports CanCanCan out of the box
   - Per-operation and per-param authorization

6. **Hooks** (`lib/rails_ops/hookup.rb`)
   - Allows operations to trigger other operations
   - Configured in `config/hookup.rb`
   - Useful for decoupled side effects

### Operation Structure

Operations should:
- Live in `app/operations/` (or custom namespace)
- Have a schemacop schema
- Be named after actions (e.g., `Create`, not `Creator`)
- Use proper namespacing (e.g., `Operations::User::Create`)
- Define schemas for param validation
- Override `perform` method for business logic
- Use policies for pre/post checks

### Testing Patterns

- Test files mirror operation structure in `test/unit/`
- Use minitest framework
- Test coverage tracked with SimpleCov
- CI tests against Ruby 2.7-3.4 and Rails 6.0-8.0

### Development Guidelines

- Follow RuboCop rules in `.rubocop.yml`
- Keep operations focused on single responsibilities
- Use sub-operations for complex workflows
- Document authorization requirements
- Ensure thread-safety (avoid runtime model definitions)
- Wrap lines in markdown files to 80 characters whenever possible
- Remove any trailing whitespace from any lines (ruby, markdown and javascript),
  also from otherwise empty lines
