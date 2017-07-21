class CreateUrl < ActiveRecord::Migration[5.1]
  def change
    create_table :urls do |t|
      t.string :link
      t.string :description
      t.string :name
    end
  end
end
