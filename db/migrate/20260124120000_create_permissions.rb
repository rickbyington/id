# frozen_string_literal: true

class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions do |t|
      t.string :name, null: false
      t.string :value

      t.timestamps
    end

    add_index :permissions, [ :name, :value ], unique: true
  end
end
