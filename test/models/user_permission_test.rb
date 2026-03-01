# frozen_string_literal: true

require "test_helper"

class UserPermissionTest < ActiveSupport::TestCase
  test "valid with user and permission" do
    user = User.create!(email: "u@x.com", password: "password123", password_confirmation: "password123")
    perm = Permission.create!(name: "test")
    up = UserPermission.new(user: user, permission: perm)
    assert up.valid?
  end

  test "uniqueness of permission_id scoped to user_id" do
    user = User.create!(email: "u@x.com", password: "password123", password_confirmation: "password123")
    perm = Permission.create!(name: "test")
    UserPermission.create!(user: user, permission: perm)
    dup = UserPermission.new(user: user, permission: perm)
    refute dup.valid?
    assert dup.errors[:permission_id].present?
  end

  test "allows same permission for different users" do
    perm = Permission.create!(name: "test")
    u1 = User.create!(email: "u1@x.com", password: "password123", password_confirmation: "password123")
    u2 = User.create!(email: "u2@x.com", password: "password123", password_confirmation: "password123")
    assert UserPermission.create!(user: u1, permission: perm).persisted?
    assert UserPermission.create!(user: u2, permission: perm).persisted?
  end
end
