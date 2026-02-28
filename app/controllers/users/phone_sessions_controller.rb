# frozen_string_literal: true

# Handles phone-number + OTP sign-in flow.
#
# GET  /signin/phone          → new   (phone number form)
# POST /signin/phone          → create (send OTP)
# GET  /signin/phone/verify   → verify (OTP entry form)
# POST /signin/phone/verify   → confirm (validate OTP, sign in)
class Users::PhoneSessionsController < ApplicationController
  include PhoneNormalization
  before_action :require_signalwire
  before_action :redirect_if_signed_in
  before_action :require_phone_in_session, only: [ :verify, :confirm ]

  RATE_LIMIT_KEY    = "phone_otp_send"
  RATE_LIMIT_MAX    = 5
  RATE_LIMIT_WINDOW = 1.hour

  def new
  end

  def create
    phone = normalize_phone(params[:phone])

    unless valid_e164?(phone)
      flash.now[:alert] = "Please enter a valid phone number (e.g. +15551234567)."
      return render :new, status: :unprocessable_entity
    end

    user = User.find_by(phone_number: phone)

    if user.nil?
      # Paranoid: don't reveal whether the number is registered
      flash[:notice] = "If that number is registered, a code has been sent."
      return redirect_to verify_phone_session_path
    end

    unless user.phone_confirmed?
      # Number exists but isn't confirmed yet → treat as continuing signup
      _record, code = PhoneOtpCode.generate_for(user, purpose: "confirmation")
      SmsService.send_otp(to: phone, code: code, purpose: "confirmation")

      session[:phone_signup_id] = user.id
      flash[:notice] = "Your number isn't confirmed yet. We've sent a new code to #{phone}."
      return redirect_to verify_phone_registration_path
    end

    if rate_limited?(phone)
      flash[:alert] = "Too many attempts. Please wait before requesting another code."
      return redirect_to new_phone_session_path
    end

    _record, code = PhoneOtpCode.generate_for(user, purpose: "sign_in")
    SmsService.send_otp(to: phone, code: code, purpose: "sign_in")
    record_rate_limit(phone)

    session[:phone_signin_number] = phone
    flash[:notice] = "A 6-digit code has been sent to your phone."
    redirect_to verify_phone_session_path
  end

  def verify
  end

  def confirm
    phone = session[:phone_signin_number]
    user  = User.find_by(phone_number: phone)

    if user.nil?
      flash[:alert] = "Session expired. Please try again."
      return redirect_to new_phone_session_path
    end

    otp = user.phone_otp_codes.for_purpose("sign_in").active.last

    if otp.nil?
      flash[:alert] = "Code has expired. Please request a new one."
      return redirect_to new_phone_session_path
    end

    if otp.verify!(params[:code].to_s.strip)
      session.delete(:phone_signin_number)
      sign_in(:user, user)
      redirect_to after_sign_in_path_for(user)
    elsif otp.locked_out?
      flash[:alert] = "Too many incorrect attempts. Please request a new code."
      redirect_to new_phone_session_path
    else
      flash.now[:alert] = "Incorrect code. Please try again."
      render :verify, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_signed_in
    redirect_to root_path if user_signed_in?
  end

  def require_phone_in_session
    unless session[:phone_signin_number].present?
      redirect_to new_phone_session_path
    end
  end

  def rate_limited?(phone)
    key   = "#{RATE_LIMIT_KEY}:#{phone}"
    count = Rails.cache.read(key).to_i
    count >= RATE_LIMIT_MAX
  end

  def record_rate_limit(phone)
    key = "#{RATE_LIMIT_KEY}:#{phone}"
    count = Rails.cache.read(key).to_i + 1
    Rails.cache.write(key, count, expires_in: RATE_LIMIT_WINDOW)
  end
end
