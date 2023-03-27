class GroupController < ApplicationController
  attr_reader :current_user
  skip_before_action :verify_authenticity_token

  def initialize
    super
    @current_user = Class.new
  end

  def show
    cls = Class.new(RailsOps::Operation::Model::Load) do
      model Group
    end

    op cls, id: params[:id]
    render json: model
  end

  def update
    cls = Class.new(RailsOps::Operation::Model::Update) do
      model Group
    end

    op cls, id: params[:id], group: {name: params[:name]}
    run!
    render json: model
  end
end
