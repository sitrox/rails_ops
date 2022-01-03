class Flower < ApplicationRecord
  # default_scope ->() { where(planted: true) }

  def self.default_scope
    where(planted: true)
  end
end
