require 'test_helper'
require 'generators/operation/operation_generator'

class OperationGeneratorTest < Rails::Generators::TestCase
  tests OperationGenerator
  destination File.expand_path('../../../tmp', File.dirname(__FILE__))

  setup do
    prepare_destination

    # Add an empty routes file
    Dir.mkdir(File.join(destination_root, 'config'))
    File.open(File.join(destination_root, 'config', 'routes.rb'), 'w') do |f|
      f.write <<~ROUTES
        Rails.application.routes.draw do
        end
      ROUTES
    end
  end

  def test_all
    run_generator ['User']

    # Check that operations are generated
    assert_operations

    # Check that views are generated
    assert_views

    # Check that the controller is generated
    assert_controller

    # Check that the routes entry is added
    assert_routes
  end

  def test_no_views
    run_generator ['User', '--skip-views']

    assert_operations
    assert_controller
    assert_routes

    # Check that the views were skipped
    %w(index show new edit).each do |view|
      assert_no_file "app/views/users/#{view}.html.haml"
    end
  end

  def test_no_controller
    run_generator ['User', '--skip-controller']

    assert_operations
    assert_views
    assert_routes

    # Check that the controller was skipped
    assert_no_file 'app/controllers/users_controller.rb'
  end

  def test_no_routes
    run_generator ['User', '--skip-routes']

    assert_operations
    assert_views
    assert_controller

    # Check that the routes were not added
    assert_file 'config/routes.rb' do |routes|
      assert_no_match(/resources :users/, routes)
    end
  end

  def test_skip_all
    run_generator ['User', '--skip-controller', '--skip-routes', '--skip-views']

    assert_operations

    # Check that the controller was skipped
    assert_no_file 'app/controllers/users_controller.rb'

    # Check that the routes were not added
    assert_file 'config/routes.rb' do |routes|
      assert_no_match(/resources :users/, routes)
    end

    # Check that the views were skipped
    %w(index show new edit).each do |view|
      assert_no_file "app/views/users/#{view}.html.haml"
    end
  end

  def test_only_operations
    run_generator ['User', '--only-operations']

    assert_operations

    # Check that the controller was skipped
    assert_no_file 'app/controllers/users_controller.rb'

    # Check that the routes were not added
    assert_file 'config/routes.rb' do |routes|
      assert_no_match(/resources :users/, routes)
    end

    # Check that the views were skipped
    %w(index show new edit).each do |view|
      assert_no_file "app/views/users/#{view}.html.haml"
    end
  end

  def test_lowercase_name
    run_generator ['user']

    # Check that operations are generated
    assert_operations

    # Check that views are generated
    assert_views

    # Check that the controller is generated
    assert_controller

    # Check that the routes entry is added
    assert_routes
  end

  private

  def assert_operations
    assert_file 'app/operations/user/create.rb' do |operation|
      assert_match(/module Operations::User/, operation)
      assert_match(/class Create < RailsOps::Operation::Model::Create/, operation)
      assert_match(/model ::User/, operation)
    end
    assert_file 'app/operations/user/destroy.rb' do |operation|
      assert_match(/module Operations::User/, operation)
      assert_match(/class Destroy < RailsOps::Operation::Model::Destroy/, operation)
      assert_match(/model ::User/, operation)
    end
    assert_file 'app/operations/user/load.rb' do |operation|
      assert_match(/module Operations::User/, operation)
      assert_match(/class Load < RailsOps::Operation::Model::Load/, operation)
      assert_match(/model ::User/, operation)
    end
    assert_file 'app/operations/user/update.rb' do |operation|
      assert_match(/module Operations::User/, operation)
      assert_match(/class Update < RailsOps::Operation::Model::Update/, operation)
      assert_match(/model ::User/, operation)
    end
  end

  def assert_views
    %w(index show new edit).each do |view|
      assert_file "app/views/users/#{view}.html.haml"
    end
  end

  def assert_controller
    assert_file 'app/controllers/users_controller.rb' do |controller|
      assert_match(/class UsersController < ApplicationController/, controller)
    end
  end

  def assert_routes
    assert_file 'config/routes.rb' do |routes|
      assert_match(/resources :users/, routes)
    end
  end
end
