class Url < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'name'
end
