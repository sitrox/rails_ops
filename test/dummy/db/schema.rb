ActiveRecord::Schema.define do
  self.verbose = false

  create_table :groups, force: true do |t|
    t.string :name
    t.string :color
    t.timestamps
  end

  create_table :animals, force: true do |t|
    t.string :type
  end

  create_table :flowers, force: true do |t|
    t.boolean :planted, null: false, default: true
  end

  create_table :computers, force: true do |t|
    t.string :name
    t.references :mainboard
  end

  create_table :mainboards, force: true do |t|
    t.string :name
    t.references :cpu
  end

  create_table :cpus, force: true do |t|
    t.string :name
  end
end
