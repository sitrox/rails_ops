class Phoenix < Bird
  belongs_to :bird, optional: true, autosave: false, inverse_of: :phoenix, validate: true
end
