# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # --- Validations ---

  test "requires email or phone_number" do
    u = User.new(password: "password123")
    refute u.valid?
    assert_includes u.errors[:base], "Email or phone number is required"
  end

  test "valid with email only" do
    u = User.new(email: "a@b.com", password: "password123", password_confirmation: "password123")
    assert u.valid?
  end

  test "valid with phone only" do
    u = User.new(phone_number: "+15551234567", password: "password123", password_confirmation: "password123")
    assert u.valid?
  end

  test "rejects invalid phone format" do
    u = User.new(phone_number: "5551234567", email: "", password: "password123", password_confirmation: "password123")
    refute u.valid?
    assert u.errors[:phone_number].present?
  end

  test "accepts E.164 phone" do
    u = User.new(phone_number: "+15551234567", email: "", password: "password123", password_confirmation: "password123")
    assert u.valid?
  end

  test "normalizes phone number (strips spaces and adds +)" do
    u = User.new(phone_number: " 555 123 4567 ", email: "", password: "password123", password_confirmation: "password123")
    u.valid?
    assert_equal "+5551234567", u.phone_number
  end

  test "password not required for phone-only user update" do
    u = User.create!(phone_number: "+15551234567", email: "", password: "password123", password_confirmation: "password123")
    u.skip_confirmation!
    u.update!(phone_number: "+15559876543")
    assert_equal "+15559876543", u.reload.phone_number
  end

  # --- Predicates ---

  test "email_user? returns true when email present" do
    u = User.new(email: "a@b.com")
    assert u.email_user?
  end

  test "email_user? returns false when email blank" do
    u = User.new(phone_number: "+15551234567")
    refute u.email_user?
  end

  test "phone_user? returns true when phone_number present" do
    u = User.new(phone_number: "+15551234567")
    assert u.phone_user?
  end

  test "phone_user? returns false when phone_number blank" do
    u = User.new(email: "a@b.com")
    refute u.phone_user?
  end

  test "phone_confirmed? returns true when phone_confirmed_at set" do
    u = User.new(phone_confirmed_at: Time.current)
    assert u.phone_confirmed?
  end

  test "phone_confirmed? returns false when phone_confirmed_at blank" do
    u = User.new(phone_number: "+15551234567")
    refute u.phone_confirmed?
  end

  # --- Confirmable (phone-only) ---

  test "skip_confirmation_notification? true when email blank" do
    u = User.new(phone_number: "+15551234567", email: "")
    assert u.skip_confirmation_notification?
  end

  test "skip_confirmation_notification? false when email present" do
    u = User.new(email: "a@b.com")
    refute u.skip_confirmation_notification?
  end

  test "confirmation_required? true when email present and not confirmed" do
    u = User.new(email: "a@b.com", confirmed_at: nil)
    assert u.confirmation_required?
  end

  test "confirmation_required? false when email blank" do
    u = User.new(phone_number: "+15551234567", email: "")
    refute u.confirmation_required?
  end

  test "confirmation_required? false when already confirmed" do
    u = User.new(email: "a@b.com", confirmed_at: 1.day.ago)
    refute u.confirmation_required?
  end

  # --- Permissions ---

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
