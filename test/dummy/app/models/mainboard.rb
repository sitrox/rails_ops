class Mainboard < ApplicationRecord
  belongs_to :cpu, optional: true, autosave: false, validate: true
end
