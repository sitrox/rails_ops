class Bird < Animal
  has_one :phoenix, inverse_of: :bird
end
