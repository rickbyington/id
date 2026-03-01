# frozen_string_literal: true

# Handles phone-number sign-up + OTP confirmation flow.
#
# GET  /signup/phone          → new     (phone number form)
# POST /signup/phone          → create  (create user, send OTP)
# GET  /signup/phone/verify   → verify  (OTP entry form)
# POST /signup/phone/verify   → confirm (validate OTP, confirm phone, sign in)
class Users::PhoneRegistrationsController < ApplicationController
  include PhoneNormalization
  before_action :require_signalwire
  before_action :redirect_if_signed_in
  before_action :require_phone_in_session, only: [ :verify, :confirm ]

  def new
    @user = User.new
  end

  def create
    phone = normalize_phone(params[:phone])

    unless valid_e164?(phone)
      @user = User.new
      flash.now[:alert] = "Please enter a valid phone number (e.g. +15551234567)."
      return render :new, status: :unprocessable_entity
    end

    user = User.find_by(phone_number: phone)

    if user.present?
      if user.phone_confirmed?
        # Number already belongs to a confirmed account → send to sign-in
        flash[:notice] = "That number is already registered. Please sign in."
        return redirect_to new_phone_session_path
      else
        # Number exists but is not confirmed → reuse the account and resend OTP
        _record, code = PhoneOtpCode.generate_for(user, purpose: "confirmation")
        SmsService.send_otp(to: phone, code: code, purpose: "confirmation")

        session[:phone_signup_id] = user.id
        flash[:notice] = "A 6-digit code has been sent to #{phone}."
        return redirect_to verify_phone_registration_path
      end
    end

    @user = User.new(phone_number: phone)

    unless @user.save
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      return render :new, status: :unprocessable_entity
    end

    _record, code = PhoneOtpCode.generate_for(@user, purpose: "confirmation")
    SmsService.send_otp(to: phone, code: code, purpose: "confirmation")

    session[:phone_signup_id] = @user.id
    flash[:notice] = "A 6-digit code has been sent to #{phone}."
    redirect_to verify_phone_registration_path
  end

  def verify
    @user = User.find_by(id: session[:phone_signup_id])
    redirect_to new_phone_registration_path unless @user
  end

  def confirm
    user = User.find_by(id: session[:phone_signup_id])

    if user.nil?
      flash[:alert] = "Session expired. Please sign up again."
      return redirect_to new_phone_registration_path
    end

    otp = user.phone_otp_codes.for_purpose("confirmation").active.last

    if otp.nil?
      flash[:alert] = "Code has expired. Please request a new one."
      return redirect_to resend_phone_registration_path
    end

    if otp.verify!(params[:code].to_s.strip)
      # Mark Devise confirmation so confirmed? returns true for phone-only users
      user.skip_confirmation!
      user.update!(phone_confirmed_at: Time.current)

      session.delete(:phone_signup_id)
      sign_in(:user, user)
      redirect_to after_sign_in_path_for(user), notice: "Welcome! Your phone number has been confirmed."
    elsif otp.locked_out?
      flash[:alert] = "Too many incorrect attempts. Please request a new code."
      redirect_to resend_phone_registration_path
    else
      @user = user
      flash.now[:alert] = "Incorrect code. Please try again."
      render :verify, status: :unprocessable_entity
    end
  end

  def resend
    user = User.find_by(id: session[:phone_signup_id])

    if user.nil?
      flash[:alert] = "Session expired. Please sign up again."
      return redirect_to new_phone_registration_path
    end

    _record, code = PhoneOtpCode.generate_for(user, purpose: "confirmation")
    SmsService.send_otp(to: user.phone_number, code: code, purpose: "confirmation")

    flash[:notice] = "A new code has been sent."
    redirect_to verify_phone_registration_path
  end

  private

  def redirect_if_signed_in
    redirect_to root_path if user_signed_in?
  end

  def require_phone_in_session
    unless session[:phone_signup_id].present?
      redirect_to new_phone_registration_path
    end
  end
end
