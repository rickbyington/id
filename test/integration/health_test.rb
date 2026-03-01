# frozen_string_literal: true

require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "GET /up returns success" do
    get rails_health_check_path
    assert_response :ok
  end
end
