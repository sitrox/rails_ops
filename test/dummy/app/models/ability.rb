class Ability
  include CanCan::Ability

  def initialize(_user)
    can :manage, :all
  end
end
