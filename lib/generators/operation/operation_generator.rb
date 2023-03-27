class OperationGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :skip_index, type: :boolean, desc: "Don't create the index route / view / controller action"
  class_option :skip_show, type: :boolean, desc: "Don't create the show route / view / controller action and the load operation"
  class_option :skip_create, type: :boolean, desc: "Don't create the new / create route / view / controller action and the create operation"
  class_option :skip_update, type: :boolean, desc: "Don't create the edit / update route / view / controller action and the update operation"
  class_option :skip_destroy, type: :boolean, desc: "Don't create the destroy route / view / controller action and the destroy operation"
  class_option :skip_controller, type: :boolean, desc: "Don't add a controller."
  class_option :skip_views, type: :boolean, desc: "Don't add the views."
  class_option :skip_routes, type: :boolean, desc: "Don't add routes to config/routes.rb."
  class_option :only_operations, type: :boolean, desc: 'Only add the operations. This is equal to specifying --skip-controller --skip-routes --skip-views'
  class_option :module, type: :string, desc: 'Add the operations in a module, e.g. "Admin" results in namespacing everything in the Admin module'

  def excluded_actions
    @excluded_actions = []

    if options[:skip_index]
      @excluded_actions += %i[index]
    end

    if options[:skip_show]
      @excluded_actions += %i[show]
    end

    if options[:skip_create]
      @excluded_actions += %i[new create]
    end

    if options[:skip_update]
      @excluded_actions += %i[edit update]
    end

    if options[:skip_destroy]
      @excluded_actions += %i[destroy]
    end
  end

  def add_operations
    @class_name = name.classify
    @underscored_name = @class_name.underscore
    @underscored_pluralized_name = @class_name.underscore.pluralize

    operations_path = 'app/operations/'

    if options[:module].present?
      @module_name = options[:module].classify
      @module_underscored_name = @module_name.underscore

      operations_path += "#{@module_underscored_name}/"
    end

    operations_path += @underscored_name.to_s

    unless @excluded_actions.include?(:show)
      template 'load.erb', "#{operations_path}/load.rb"
    end
    unless @excluded_actions.include?(:create)
      template 'create.erb', "#{operations_path}/create.rb"
    end
    unless @excluded_actions.include?(:update)
      template 'update.erb', "#{operations_path}/update.rb"
    end
    unless @excluded_actions.include?(:destroy)
      template 'destroy.erb', "#{operations_path}/destroy.rb"
    end
  end

  def add_controller
    return if options[:skip_controller] || options[:only_operations]

    controller_file_path = 'app/controllers/'
    if @module_underscored_name.present?
      controller_file_path += "#{@module_underscored_name}/"
    end
    controller_file_path += "#{@underscored_pluralized_name}_controller.rb"
    @controller_name = "#{@class_name.pluralize}Controller"

    template 'controller_wrapper.erb', controller_file_path
  end

  def add_views
    return if options[:skip_views] || options[:only_operations]

    views_folder = 'app/views/'
    if @module_underscored_name.present?
      views_folder += "#{@module_underscored_name}/"
    end
    views_folder += @underscored_pluralized_name.to_s

    actions = %w[index show new edit]

    @excluded_actions.each do |a|
      actions.delete(a.to_s)
    end

    actions.each do |view|
      template 'view.erb', "#{views_folder}/#{view}.html.haml"
    end
  end

  def add_routes
    return if options[:skip_routes] || options[:only_operations]

    if @excluded_actions.empty?
      route "resources :#{@underscored_pluralized_name}"
    else
      route "resources :#{@underscored_pluralized_name}, except: #{@excluded_actions}"
    end
  end
end
