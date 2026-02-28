# frozen_string_literal: true

require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "GET / when not signed in redirects to sign in" do
    get root_path
    assert_response :redirect
    assert response.location.include?("signin")
  end

  test "GET / when signed in returns success and shows welcome" do
    user = User.create!(email: "welcome@example.com", password: "password123")
    user.confirm
    sign_in user
    get root_path
    assert_response :ok
    assert response.body.include?("Welcome")
    assert response.body.include?("welcome@example.com")
  end

  test "GET / when signed in with authorized applications shows app and revoke button" do
    user = User.create!(email: "welcome@example.com", password: "password123")
    user.confirm
    app = create_oauth_application(name: "My App", redirect_uri: "https://myapp.com/callback")
    Doorkeeper::AccessToken.create!(
      application_id: app.id,
      resource_owner_id: user.id,
      scopes: "openid profile",
      expires_in: 7200
    )
    sign_in user
    get root_path
    assert_response :ok
    assert response.body.include?("My App")
    assert response.body.include?("Revoke access")
    assert response.body.include?("Last authorized")
  end

  test "DELETE authorized_applications when not signed in redirects to root with alert" do
    app = create_oauth_application(name: "Revoke Me", redirect_uri: "https://revoke.com/cb")
    delete revoke_authorized_application_path(app.id)
    assert_response :redirect
    follow_redirect!
    follow_redirect! while response.redirect?
    assert response.body.include?("Not allowed"), "Expected body to include 'Not allowed', got: #{response.body[0, 200]}"
  end

  test "DELETE authorized_applications when signed in with token revokes and redirects with notice" do
    user = User.create!(email: "revoke@example.com", password: "password123")
    user.confirm
    app = create_oauth_application(name: "Revoke Me", redirect_uri: "https://revoke.com/cb")
    Doorkeeper::AccessToken.create!(
      application_id: app.id,
      resource_owner_id: user.id,
      scopes: "openid",
      expires_in: 7200
    )
    sign_in user
    delete revoke_authorized_application_path(app.id)
    assert_response :see_other
    follow_redirect!
    assert response.body.include?("Access to Revoke Me has been revoked")
    assert Doorkeeper::AccessToken.where(resource_owner_id: user.id, application_id: app.id, revoked_at: nil).empty?
  end

  test "DELETE authorized_applications when application does not exist redirects with alert" do
    user = User.create!(email: "revoke@example.com", password: "password123")
    user.confirm
    sign_in user
    delete revoke_authorized_application_path(999_999)
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("Application not found")
  end

  test "DELETE authorized_applications when user has no token redirects with notice" do
    user = User.create!(email: "revoke@example.com", password: "password123")
    user.confirm
    app = create_oauth_application(name: "Revoke Me", redirect_uri: "https://revoke.com/cb")
    sign_in user
    delete revoke_authorized_application_path(app.id)
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("No active access")
  end
end
