require 'test_helper'

class RailsOps::Mixins::Model::DeepNestingTest < ActiveSupport::TestCase
  include TestHelper

  CPU_CREATION_OP = Class.new(RailsOps::Operation::Model::Create) do
    model Cpu do
      validates :name, presence: true
    end
  end

  MAINBOARD_CREATION_OP = Class.new(RailsOps::Operation::Model::Create) do
    model Mainboard do
      validates :name, presence: true
    end

    nest_model_op :cpu, CPU_CREATION_OP
  end

  COMPUTER_CREATION_OP = Class.new(RailsOps::Operation::Model::Create) do
    model Computer do
      validates :name, presence: true
    end

    nest_model_op :mainboard, MAINBOARD_CREATION_OP
  end

  CPU_UPDATE_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Cpu do
      validates :name, presence: true
    end
  end

  MAINBOARD_UPDATE_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Mainboard do
      validates :name, presence: true
    end

    nest_model_op :cpu, CPU_UPDATE_OP
  end

  COMPUTER_UPDATE_OP = Class.new(RailsOps::Operation::Model::Update) do
    model Computer do
      validates :name, presence: true
    end

    nest_model_op :mainboard, MAINBOARD_UPDATE_OP
  end

  def test_create_cpu
    assert_nothing_raised do
      CPU_CREATION_OP.run!(cpu: { name: 'CPU' })
    end
  end

  def test_create_mainboard
    assert_nothing_raised do
      MAINBOARD_CREATION_OP.run!(
        mainboard: {
          name:           'Mainboard',
          cpu_attributes: {
            name: 'CPU'
          }
        }
      )
    end
  end

  def test_create_computer_success
    model = assert_nothing_raised do
      COMPUTER_CREATION_OP.run!(
        computer: {
          name:                 'Computer',

          mainboard_attributes: {
            name:           'Mainboard',

            cpu_attributes: {
              name: 'CPU'
            }
          }
        }
      ).model
    end

    assert 'Computer', model.persisted?
    assert 'Mainboard', model.mainboard.persisted?
    assert 'CPU', model.mainboard.cpu.persisted?

    assert_equal 'Computer', model.name
    assert_equal 'Mainboard', model.mainboard.name
    assert_equal 'CPU', model.mainboard.cpu.name
  end

  def test_without_asoc
    assert_raises_with_message RuntimeError, 'Association cat could not be found for Animal.' do
      Class.new(RailsOps::Operation::Model::Create) do
        model Animal

        nest_model_op :cat, Class.new(RailsOps::Operation::Model::Create) do
          model Cat
        end
      end
    end
  end

  def test_wrong_asoc_type
    assert_raises_with_message RuntimeError,
                               'Method nest_model_op only supports :belongs_to associations, but association dogs of model Animal is a has_many association.' do
      Class.new(RailsOps::Operation::Model::Create) do
        model Animal

        nest_model_op :dogs, Class.new(RailsOps::Operation::Model::Create) do
          model Dog
        end
      end
    end
  end

  def test_autosave_on
    assert_raises_with_message RuntimeError, 'Association bird of Animal has :autosave turned on. This is not supported by nest_model_op.' do
      Class.new(RailsOps::Operation::Model::Create) do
        model Animal

        nest_model_op :bird, Class.new(RailsOps::Operation::Model::Create) do
          model Bird
        end
      end
    end
  end

  def test_validation_off
    assert_raises_with_message RuntimeError, 'Association phoenix of Animal has :validate turned off. This is not supported by nest_model_op.' do
      Class.new(RailsOps::Operation::Model::Create) do
        model Animal

        nest_model_op :phoenix, Class.new(RailsOps::Operation::Model::Create) do
          model Phoenix
        end
      end
    end
  end

  def test_inverse_autosave_on
    assert_raises_with_message RuntimeError, 'Association phoenix of Bird has :autosave turned on. This is not supported by nest_model_op.' do
      Class.new(RailsOps::Operation::Model::Create) do
        model Phoenix

        nest_model_op :bird, Class.new(RailsOps::Operation::Model::Create) do
          model Bird
        end
      end
    end
  end

  def test_create_computer_level_1_validation_error
    op = COMPUTER_CREATION_OP.new(
      computer: {
        mainboard_attributes: {
          name:           'Mainboard',

          cpu_attributes: {
            name: 'CPU'
          }
        }
      }
    )

    assert_raises_with_message ActiveRecord::RecordInvalid, /Name can't be blank/ do
      op.run!
    end

    assert_equal ["Name can't be blank"], op.model.errors.full_messages
    refute op.model.persisted?
  end

  def test_create_computer_level_2_validation_error
    op = COMPUTER_CREATION_OP.new(
      computer: {
        name:                 'Computer',

        mainboard_attributes: {
          cpu_attributes: {
            name: 'CPU'
          }
        }
      }
    )

    assert_raises_with_message ActiveRecord::RecordInvalid, /Mainboard is invalid/ do
      op.run!
    end

    assert_equal ['Mainboard is invalid'], op.model.errors.full_messages
    refute op.model.persisted?

    assert_equal ["Name can't be blank"], op.model.mainboard.errors.full_messages
    refute op.model.mainboard.persisted?
  end

  def test_create_computer_level_3_validation_error
    op = COMPUTER_CREATION_OP.new(
      computer: {
        name:                 'Computer',

        mainboard_attributes: {
          name:           'Mainboard',

          cpu_attributes: {}
        }
      }
    )

    assert_raises_with_message ActiveRecord::RecordInvalid, /Mainboard is invalid/ do
      op.run!
    end

    assert_equal ['Mainboard is invalid'], op.model.errors.full_messages
    refute op.model.persisted?

    assert_equal ['Cpu is invalid'], op.model.mainboard.errors.full_messages
    refute op.model.mainboard.persisted?

    assert_equal ["Name can't be blank"], op.model.mainboard.cpu.errors.full_messages
    refute op.model.mainboard.cpu.persisted?
  end

  def test_update_validation_error
    create_op = COMPUTER_CREATION_OP.new(
      computer: {
        name:                 'Computer',

        mainboard_attributes: {
          name:           'Mainboard',

          cpu_attributes: {
            name: 'CPU'
          }
        }
      }
    )

    create_op.run!

    update_op = COMPUTER_UPDATE_OP.new(
      id:       Computer.first,
      computer: {
        name:                 'Computer',

        mainboard_attributes: {
          name:           '',

          cpu_attributes: {
            name: 'CPU'
          }
        }
      }
    )

    refute update_op.run
    assert update_op.model.mainboard.errors.added?(:name, :blank)
  end
end
