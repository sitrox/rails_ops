class OperationGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :skip_controller, type: :boolean, desc: "Don't add a controller."
  class_option :skip_views, type: :boolean, desc: "Don't add the views."
  class_option :skip_routes, type: :boolean, desc: "Don't add routes to config/routes.rb."
  class_option :only_operations, type: :boolean, desc: 'Only add the operations. This is equal to specifying --skip-controller --skip-routes --skip-views'
  class_option :module, type: :string, desc: 'Add the operations in a module, e.g. "Admin" results in namespacing everything in the Admin module'

  def add_operations
    @class_name = name.classify
    @underscored_name = name.underscore
    @underscored_pluralized_name = name.underscore.pluralize

    operations_path = 'app/operations/'

    if options[:module].present?
      @module_name = options[:module].classify
      @module_underscored_name = @module_name.underscore

      operations_path += "#{@module_underscored_name}/"
    end

    operations_path += @underscored_name.to_s

    template 'load.erb', "#{operations_path}/load.rb"
    template 'create.erb', "#{operations_path}/create.rb"
    template 'update.erb', "#{operations_path}/update.rb"
    template 'destroy.erb', "#{operations_path}/destroy.rb"
  end

  def add_controller
    return if options[:skip_controller] || options[:only_operations]

    controller_file_path = 'app/controllers/'
    if @module_underscored_name.present?
      controller_file_path += "#{@module_underscored_name}/"
    end
    controller_file_path += "#{@underscored_pluralized_name}_controller.rb"
    @controller_name = "#{@class_name.pluralize}Controller"

    template 'controller.erb', controller_file_path
  end

  def add_views
    return if options[:skip_views] || options[:only_operations]

    views_folder = 'app/views/'
    if @module_underscored_name.present?
      views_folder += "#{@module_underscored_name}/"
    end
    views_folder += @underscored_pluralized_name.to_s

    %w[index show new edit].each do |view|
      template 'view.erb', "#{views_folder}/#{view}.html.haml"
    end
  end

  def add_routes
    return if options[:skip_routes] || options[:only_operations]

    route "resources :#{@underscored_pluralized_name}"
  end
end
