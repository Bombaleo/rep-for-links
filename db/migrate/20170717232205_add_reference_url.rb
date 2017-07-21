class AddReferenceUrl < ActiveRecord::Migration[5.1]
  def change
    add_reference :urls, :user, foreign_key: 'name'
  end
end
  
