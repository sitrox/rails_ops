# Mixin for the {RailsOps::Operation} class that provides *policies*. Policies
# are simple blocks of code that run at specific places in your operation and
# can be used to check conditions such as params or permissions. Policies are
# inherited to subclasses of operations.
module RailsOps::Mixins::Policies
  extend ActiveSupport::Concern

  POLICY_CHAIN_KEYS = [
    :on_init,
    :before_perform,
    :after_perform,
    :before_nested_model_ops,
    :before_model_save
  ].freeze

  included do
    class_attribute :_policy_chains
    self._policy_chains = Hash[POLICY_CHAIN_KEYS.map { |key| [key, [].freeze] }]
  end

  module ClassMethods
    # Register a new policy block that will be executed in the given `chain`.
    # The policy block will be executed in the operation's instance context.
    def policy(chain = :before_perform, &block)
      unless POLICY_CHAIN_KEYS.include?(chain)
        fail "Unknown policy chain #{chain.inspect}, available are #{POLICY_CHAIN_KEYS.inspect}."
      end

      self._policy_chains = _policy_chains.dup
      _policy_chains[chain] += [block]
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
