require 'test_helper'

class RailsOps::Operation::Model::StiTest < ActiveSupport::TestCase
  include TestHelper

  setup do
    @dog = Dog.create!
    @cat = Cat.create!
    @phoenix = Phoenix.create!
    @nightingale = Nightingale.create!
  end

  LOAD_ANIMAL_OP = Class.new(RailsOps::Operation::Model::Load) do
    model Animal do
      attribute :my_virtual_animal_name
    end
  end

  LOAD_DOG_OP = Class.new(RailsOps::Operation::Model::Load) do
    model Dog do
      attribute :my_virtual_dog_name
    end
  end

  LOAD_BIRD_OP = Class.new(RailsOps::Operation::Model::Load) do
    model Bird do
      attribute :my_virtual_bird_name
    end
  end

  LOAD_PHOENIX_OP = Class.new(RailsOps::Operation::Model::Load) do
    model Phoenix do
      attribute :my_virtual_phoenix_name
    end
  end

  UPDATE_DOG_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Dog do
      attribute :my_virtual_dog_name
    end
  end

  CREATE_DOG_OP = Class.new(RailsOps::Operation::Model::Create) do
    model Dog do
      attribute :my_virtual_dog_name
    end
  end

  UPDATE_PHOENIX_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Phoenix do
      attribute :my_virtual_phoenix_name
    end
  end

  CREATE_PHOENIX_OP = Class.new(RailsOps::Operation::Model::Create) do
    model Phoenix do
      attribute :my_virtual_phoenix_name
    end
  end

  def test_load_animal
    model = LOAD_ANIMAL_OP.new(id: @dog.id).model
    assert_equal 'Dog', model.type
    assert model.is_a?(LOAD_ANIMAL_OP.model)
    assert_nothing_raised { model.my_virtual_animal_name = 'Lenny' }
  end

  def test_load_dog
    model = LOAD_DOG_OP.new(id: @dog.id).model

    assert_equal 'Dog', model.type
    assert model.is_a?(LOAD_DOG_OP.model)
    assert_nothing_raised { model.my_virtual_dog_name = 'Lenny' }
  end

  def test_load_birds
    phoenix = LOAD_BIRD_OP.new(id: @phoenix.id).model
    nightingale = LOAD_BIRD_OP.new(id: @nightingale.id).model

    assert_equal 'Phoenix', phoenix.type
    assert phoenix.is_a?(LOAD_BIRD_OP.model)
    assert nightingale.is_a?(LOAD_BIRD_OP.model)
    assert_nothing_raised { phoenix.my_virtual_bird_name = 'Lenny' }
    assert_nothing_raised { nightingale.my_virtual_bird_name = 'Lenny' }
  end

  def test_load_phoenix
    model = LOAD_PHOENIX_OP.new(id: @phoenix.id).model

    assert_equal 'Phoenix', model.type
    assert model.is_a?(LOAD_PHOENIX_OP.model)
    assert_nothing_raised { model.my_virtual_phoenix_name = 'Lenny' }
  end

  def test_create_dog
    op = CREATE_DOG_OP.new.run!

    assert_equal 'Dog', op.model.type
    assert op.model.is_a?(CREATE_DOG_OP.model)
    assert_nothing_raised { op.model.my_virtual_dog_name = 'Lenny' }
  end

  def test_update_dog
    op = UPDATE_DOG_OP.new(id: @dog.id).run!

    assert_equal 'Dog', op.model.type
    assert op.model.is_a?(UPDATE_DOG_OP.model)
    assert_nothing_raised { op.model.my_virtual_dog_name = 'Lenny' }
  end

  def test_create_phoenix
    op = CREATE_PHOENIX_OP.new.run!

    assert_equal 'Phoenix', op.model.type
    assert op.model.is_a?(CREATE_PHOENIX_OP.model)
    assert_nothing_raised { op.model.my_virtual_phoenix_name = 'Lenny' }
  end

  def test_update_phoenix
    op = UPDATE_PHOENIX_OP.new(id: @phoenix.id).run!

    assert_equal 'Phoenix', op.model.type
    assert op.model.is_a?(UPDATE_PHOENIX_OP.model)
    assert_nothing_raised { op.model.my_virtual_phoenix_name = 'Lenny' }
  end
end
