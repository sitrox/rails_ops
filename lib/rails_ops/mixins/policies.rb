# Mixin for the {RailsOps::Operation} class that provides *policies*. Policies
# are simple blocks of code that run at specific places in your operation and
# can be used to check conditions such as params or permissions. Policies are
# inherited to subclasses of operations.
module RailsOps::Mixins::Policies
  extend ActiveSupport::Concern

  POLICY_CHAIN_KEYS = %i[
    before_attr_assign
    on_init
    before_perform
    after_perform
    before_nested_model_ops
    before_model_validation
    before_model_save
  ].freeze

  included do
    class_attribute :_policy_chains
    self._policy_chains = POLICY_CHAIN_KEYS.map { |key| [key, [].freeze] }.to_h
  end

  module ClassMethods
    # Register a new policy block that will be executed in the given `chain`.
    # The policy block will be executed in the operation's instance context.
    def policy(chain = :before_perform, prepend_action: false, &block)
      unless POLICY_CHAIN_KEYS.include?(chain)
        fail "Unknown policy chain #{chain.inspect}, available are #{POLICY_CHAIN_KEYS.inspect}."
      end

      # The `before_attr_assign` chain is only allowed if the operation is a model
      # operation, i.e. it needs to implement the `build_model` method.
      if chain == :before_attr_assign && !method_defined?(:assign_attributes)
        fail 'Policy :before_attr_assign may not be used unless your operation defines the `assign_attributes` method!'
      end

      # The `before_model_validation` chain is only allowed if the operation
      # is a model operation, i.e. it needs to implement the `build_model`
      # method.
      if chain == :before_model_validation && !method_defined?(:build_model)
        fail 'Policy :before_model_validation may not be used unless your operation defines the `build_model` method!'
      end

      self._policy_chains = _policy_chains.dup
      if prepend_action
        _policy_chains[chain] = [block] + _policy_chains[chain]
      else
        _policy_chains[chain] += [block]
      end
    end

    # Returns all registered validation blocks for this operation class.
    def policies_for(chain)
      unless POLICY_CHAIN_KEYS.include?(chain)
        fail "Unknown policy chain #{chain.inspect}, available are #{POLICY_CHAIN_KEYS.inspect}."
      end

      return _policy_chains[chain]
    end
  end

  def run_policies(chain)
    self.class.policies_for(chain).each do |block|
      instance_eval(&block)
    end
  end
end
