$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_record'
require 'minitest/autorun'
require 'rails_ops'
require 'db/models'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

module TestHelper
  extend ActiveSupport::Concern

  module ClassMethods
    def setup_db
      load File.dirname(__FILE__) + '/db/schema.rb'
    end

    def setup_base_data; end
  end
end
