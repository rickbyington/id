# frozen_string_literal: true

class CreateLoginActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :login_activities do |t|
      t.string :scope
      t.string :strategy
      t.string :identity
      t.boolean :success
      t.string :failure_reason
      t.references :user, polymorphic: true
      t.string :context
      t.string :ip
      t.text :user_agent
      t.string :referrer
      t.string :city
      t.string :region
      t.string :country
      t.float :latitude
      t.float :longitude

      t.timestamps
    end

    add_index :login_activities, [:user_type, :user_id]
    add_index :login_activities, :created_at
  end
end
