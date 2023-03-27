require 'test_helper'
require 'generators/operation/operation_generator'

class OperationGeneratorTest < Rails::Generators::TestCase
  tests OperationGenerator
  destination File.expand_path('../../../tmp', File.dirname(__FILE__))

  setup do
    prepare_destination

    # Add an empty routes file
    Dir.mkdir(File.join(destination_root, 'config'))
    File.write(File.join(destination_root, 'config', 'routes.rb'), <<~ROUTES)
      Rails.application.routes.draw do
      end
    ROUTES
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

  def test_no_index_action
    run_generator ['User', '--skip-index']

    # Check that the index view is not created
    assert_no_file 'app/views/users/index.html.haml'

    # Check that the index route is not created
    assert_file 'config/routes.rb' do |routes|
      assert_match(/resources :users, except: \[:index\]/, routes)
    end

    # Check that the controller action is not created
    assert_file 'app/controllers/users_controller.rb' do |controller|
      assert_no_match(/def index/, controller)
    end
  end

  def test_no_show_action
    run_generator ['User', '--skip-show']

    # Check that the show view is not created
    assert_no_file 'app/views/users/show.html.haml'

    # Check that the show route is not created
    assert_file 'config/routes.rb' do |routes|
      assert_match(/resources :users, except: \[:show\]/, routes)
    end

    # Check that the controller action is not created
    assert_file 'app/controllers/users_controller.rb' do |controller|
      assert_no_match(/def show/, controller)
    end

    # Check that the load operation is not created
    assert_no_file 'app/operations/users/load.rb'
  end

  def test_no_create_action
    run_generator ['User', '--skip-create']

    # Check that the new and create view are not created
    assert_no_file 'app/views/users/new.html.haml'
    assert_no_file 'app/views/users/create.html.haml'

    # Check that the new, create route is not created
    assert_file 'config/routes.rb' do |routes|
      assert_match(/resources :users, except: \[:new, :create\]/, routes)
    end

    # Check that the controller actions are not created
    assert_file 'app/controllers/users_controller.rb' do |controller|
      assert_no_match(/def new/, controller)
      assert_no_match(/def create/, controller)
    end

    # Check that the load operation is not created
    assert_no_file 'app/operations/users/create.rb'
  end

  def test_no_update_action
    run_generator ['User', '--skip-update']

    # Check that the edit and update view are not created
    assert_no_file 'app/views/users/edit.html.haml'
    assert_no_file 'app/views/users/update.html.haml'

    # Check that the edit, update route is not created
    assert_file 'config/routes.rb' do |routes|
      assert_match(/resources :users, except: \[:edit, :update\]/, routes)
    end

    # Check that the controller actions are not created
    assert_file 'app/controllers/users_controller.rb' do |controller|
      assert_no_match(/def edit/, controller)
      assert_no_match(/def update/, controller)
    end

    # Check that the load operation is not created
    assert_no_file 'app/operations/users/update.rb'
  end

  def test_no_destory_action
    run_generator ['User', '--skip-destroy']

    # Check that the destroy view is not created
    assert_no_file 'app/views/users/destroy.html.haml'

    # Check that the destroy route is not created
    assert_file 'config/routes.rb' do |routes|
      assert_match(/resources :users, except: \[:destroy\]/, routes)
    end

    # Check that the controller action is not created
    assert_file 'app/controllers/users_controller.rb' do |controller|
      assert_no_match(/def destroy/, controller)
    end
  end

  def test_no_views
    run_generator ['User', '--skip-views']

    assert_operations
    assert_controller
    assert_routes

    # Check that the views were skipped
    %w[index show new edit].each do |view|
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
    %w[index show new edit].each do |view|
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
    %w[index show new edit].each do |view|
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

  def test_module_name
    optiongroups = [['User', '--module=Admin'], ['User', '--module=admin']]

    optiongroups.each do |optiongroup|
      run_generator optiongroup

      # Check that namespaced operations are generated
      assert_file 'app/operations/admin/user/create.rb' do |operation|
        assert_match(/module Operations::Admin::User/, operation)
        assert_match(/class Create < RailsOps::Operation::Model::Create/, operation)
        assert_match(/model ::User/, operation)
      end
      assert_file 'app/operations/admin/user/destroy.rb' do |operation|
        assert_match(/module Operations::Admin::User/, operation)
        assert_match(/class Destroy < RailsOps::Operation::Model::Destroy/, operation)
        assert_match(/model ::User/, operation)
      end
      assert_file 'app/operations/admin/user/load.rb' do |operation|
        assert_match(/module Operations::Admin::User/, operation)
        assert_match(/class Load < RailsOps::Operation::Model::Load/, operation)
        assert_match(/model ::User/, operation)
      end
      assert_file 'app/operations/admin/user/update.rb' do |operation|
        assert_match(/module Operations::Admin::User/, operation)
        assert_match(/class Update < RailsOps::Operation::Model::Update/, operation)
        assert_match(/model ::User/, operation)
      end

      # Check that views are generated
      %w[index show new edit].each do |view|
        assert_file "app/views/admin/users/#{view}.html.haml"
      end

      # Check that the controller is generated
      assert_file 'app/controllers/admin/users_controller.rb' do |controller|
        assert_match(/module Admin/, controller)
        assert_match(/class UsersController < ApplicationController/, controller)
      end

      # Check that the routes entry is added
      assert_routes
    end
  end

  def test_nested_module_name
    run_generator ['User', '--module=admin/foo']

    # Check that namespaced operations are generated
    assert_file 'app/operations/admin/foo/user/create.rb' do |operation|
      assert_match(/module Operations::Admin::Foo::User/, operation)
      assert_match(/class Create < RailsOps::Operation::Model::Create/, operation)
      assert_match(/model ::User/, operation)
    end
    assert_file 'app/operations/admin/foo/user/destroy.rb' do |operation|
      assert_match(/module Operations::Admin::Foo::User/, operation)
      assert_match(/class Destroy < RailsOps::Operation::Model::Destroy/, operation)
      assert_match(/model ::User/, operation)
    end
    assert_file 'app/operations/admin/foo/user/load.rb' do |operation|
      assert_match(/module Operations::Admin::Foo::User/, operation)
      assert_match(/class Load < RailsOps::Operation::Model::Load/, operation)
      assert_match(/model ::User/, operation)
    end
    assert_file 'app/operations/admin/foo/user/update.rb' do |operation|
      assert_match(/module Operations::Admin::Foo::User/, operation)
      assert_match(/class Update < RailsOps::Operation::Model::Update/, operation)
      assert_match(/model ::User/, operation)
    end

    # Check that views are generated
    %w[index show new edit].each do |view|
      assert_file "app/views/admin/foo/users/#{view}.html.haml"
    end

    # Check that the controller is generated
    assert_file 'app/controllers/admin/foo/users_controller.rb' do |controller|
      assert_match(/module Admin::Foo/, controller)
      assert_match(/class UsersController < ApplicationController/, controller)
    end

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
    %w[index show new edit].each do |view|
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
