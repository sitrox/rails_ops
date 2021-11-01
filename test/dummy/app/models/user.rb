class User < ApplicationRecord
  belongs_to :group#, validate: true
end
