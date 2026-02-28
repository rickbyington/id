# frozen_string_literal: true

module AuthTrail
  class LoginActivity < ::ApplicationRecord
    self.table_name = "login_activities"

    belongs_to :user, polymorphic: true, optional: true
  end
end
