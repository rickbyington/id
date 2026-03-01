# frozen_string_literal: true

require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  test "valid with name" do
    p = Permission.new(name: "invoice_reader")
    assert p.valid?
  end

  test "invalid without name" do
    p = Permission.new(name: nil)
    refute p.valid?
    assert_includes p.errors[:name], "can't be blank"
  end

  test "has many user_permissions" do
    perm = Permission.create!(name: "test")
    user = User.create!(email: "u@x.com", password: "password123", password_confirmation: "password123")
    up = UserPermission.create!(user: user, permission: perm)
    assert_includes perm.user_permissions, up
  end

  test "has many users through user_permissions" do
    perm = Permission.create!(name: "test")
    user = User.create!(email: "u@x.com", password: "password123", password_confirmation: "password123")
    UserPermission.create!(user: user, permission: perm)
    assert_includes perm.users, user
  end
end
