class Computer < ApplicationRecord
  belongs_to :mainboard, optional: true, autosave: false, validate: true
end
