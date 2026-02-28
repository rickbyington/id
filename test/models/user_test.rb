# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has_permission? returns false when user has no permissions" do
    user = User.create!(email: "perm@example.com", password: "password123")
    Permission.create!(name: "invoice_reader", value: "true")
    assert_equal false, user.has_permission?("invoice_reader")
  end

  test "has_permission? returns true when user has the permission (no value)" do
    user = User.create!(email: "perm@example.com", password: "password123")
    perm = Permission.create!(name: "invoice_reader", value: "true")
    UserPermission.create!(user: user, permission: perm)
    assert_equal true, user.has_permission?("invoice_reader")
  end

  test "has_permission? returns true when user has the permission with matching value" do
    user = User.create!(email: "perm@example.com", password: "password123")
    perm = Permission.create!(name: "invoices", value: "write")
    UserPermission.create!(user: user, permission: perm)
    assert_equal true, user.has_permission?("invoices", "write")
  end

  test "has_permission? returns false when user has permission but value does not match" do
    user = User.create!(email: "perm@example.com", password: "password123")
    perm = Permission.create!(name: "invoices", value: "write")
    UserPermission.create!(user: user, permission: perm)
    assert_equal false, user.has_permission?("invoices", "read")
  end

  test "has_permission? returns false for non-existent permission name" do
    user = User.create!(email: "perm@example.com", password: "password123")
    assert_equal false, user.has_permission?("nonexistent")
  end

  test "permission_value returns nil when user has no such permission" do
    user = User.create!(email: "val@example.com", password: "password123")
    Permission.create!(name: "invoice_reader", value: "true")
    assert_nil user.permission_value("invoice_reader")
  end

  test "permission_value returns the value when user has the permission" do
    user = User.create!(email: "val@example.com", password: "password123")
    perm = Permission.create!(name: "invoice_reader", value: "true")
    UserPermission.create!(user: user, permission: perm)
    assert_equal "true", user.permission_value("invoice_reader")
  end
end
