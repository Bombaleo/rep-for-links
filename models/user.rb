class User < ActiveRecord::Base
  self.primary_key = 'name'
  has_many :urls, :foreign_key => :name
end
