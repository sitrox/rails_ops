rails_ops
=========

**This Gem is still under development and is not to be used in production yet.**

This Gem introduces an additional service layer for Rails: *Operations*. An
operation is in most cases a *business action* or *use case* and may or may not
involve one or multiple models. Rails Ops allow creating more modular
applications by splitting them up into its different operations. Each operation
is specified in a single, testable class.

To achieve this goal, this Gem provides the following building blocks:

- Various operation base classes for creating operations with a consistent
  interface and no boilerplate code.

- A way of abstracting model classes for a specific business action.
