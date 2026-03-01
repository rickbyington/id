# frozen_string_literal: true

require "test_helper"

class PhoneNormalizationTest < ActiveSupport::TestCase
  # Test the concern via a minimal class that includes it
  class DummyController
    include PhoneNormalization
  end

  setup do
    @subject = DummyController.new
  end

  test "normalize_phone returns empty string for blank" do
    assert_equal "", @subject.send(:normalize_phone, nil)
    assert_equal "", @subject.send(:normalize_phone, "")
    assert_equal "", @subject.send(:normalize_phone, "   ")
  end

  test "normalize_phone strips spaces dashes parens" do
    # Concern only strips and adds +; it does not insert country code 1
    assert_equal "+5551234567", @subject.send(:normalize_phone, " (555) 123-4567 ")
    assert_equal "+5551234567", @subject.send(:normalize_phone, "555-123-4567")
  end

  test "normalize_phone adds leading + when missing" do
    assert_equal "+15551234567", @subject.send(:normalize_phone, "15551234567")
  end

  test "normalize_phone keeps leading + when present" do
    assert_equal "+15551234567", @subject.send(:normalize_phone, "+15551234567")
  end

  test "valid_e164? returns true for valid E.164" do
    assert @subject.send(:valid_e164?, "+15551234567")
    assert @subject.send(:valid_e164?, "+442071234567")
  end

  test "valid_e164? returns false for invalid formats" do
    refute @subject.send(:valid_e164?, "5551234567")
    refute @subject.send(:valid_e164?, "+05551234567")
    refute @subject.send(:valid_e164?, "+123")
    refute @subject.send(:valid_e164?, "")
  end
end
