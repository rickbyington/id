# frozen_string_literal: true

require "test_helper"

class OmniauthCallbacksControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  tests OmniauthCallbacksController

  setup do
    @routes = Rails.application.routes
  end

  test "google_oauth2 without email redirects with alert" do
    request.env["omniauth.auth"] = { "info" => { "email" => nil } }
    get :google_oauth2
    assert_redirected_to new_user_session_path
    assert_match(/did not provide an email/, flash[:alert])
  end

  test "google_oauth2 with email finds existing user and signs in" do
    user = User.create!(email: "google@example.com", password: "password123", password_confirmation: "password123")
    user.confirm
    request.env["omniauth.auth"] = {
      "info" => { "email" => "google@example.com", "first_name" => "John", "last_name" => "Doe" }
    }
    get :google_oauth2
    assert_redirected_to root_path
    assert_match(/Signed in with Google/, flash[:notice])
  end

  test "google_oauth2 with new email creates user and signs in" do
    request.env["omniauth.auth"] = {
      "info" => { "email" => "newgoogle@example.com", "first_name" => "Jane", "last_name" => "Doe" }
    }
    assert_difference "User.count", 1 do
      get :google_oauth2
    end
    assert_redirected_to root_path
    assert User.find_by(email: "newgoogle@example.com")
  end

  test "github without email redirects with alert" do
    request.env["omniauth.auth"] = { "info" => {}, "extra" => { "raw_info" => {} } }
    get :github
    assert_redirected_to new_user_session_path
    assert_match(/did not provide an email|GitHub/, flash[:alert])
  end

  test "github with email in info finds existing user" do
    user = User.create!(email: "github@example.com", password: "password123", password_confirmation: "password123")
    user.confirm
    request.env["omniauth.auth"] = {
      "info" => { "email" => "github@example.com", "name" => "Git User" },
      "extra" => { "raw_info" => {} }
    }
    get :github
    assert_redirected_to root_path
    assert_match(/Signed in with GitHub/, flash[:notice])
  end

  test "failure redirects to sign in with alert" do
    get :failure
    assert_redirected_to new_user_session_path
    assert flash[:alert].present?
  end
end
