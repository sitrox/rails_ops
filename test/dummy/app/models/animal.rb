class Animal < ApplicationRecord
  has_many :dogs
  belongs_to :bird, optional: true
  belongs_to :phoenix, optional: true, validate: false, autosave: false
end
