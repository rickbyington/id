# frozen_string_literal: true

# Change or add phone number for the signed-in user. Sends OTP to the new number;
# only updates user.phone_number and phone_confirmed_at after successful verification.
#
# GET  /account/phone         → new    (phone number form)
# POST /account/phone         → create (send OTP to new number)
# GET  /account/phone/verify  → verify (OTP entry form)
# POST /account/phone/verify  → confirm (verify OTP, update user)
class Users::PhoneChangesController < ApplicationController
  include PhoneNormalization
  before_action :authenticate_user!
  before_action :require_signalwire
  before_action :require_phone_in_session, only: [ :verify, :confirm ]

  def new
  end

  def create
    phone = normalize_phone(params[:phone])

    unless valid_e164?(phone)
      flash.now[:alert] = "Please enter a valid phone number (e.g. +15551234567)."
      return render :new, status: :unprocessable_entity
    end

    # Don't allow changing to a number already on another account
    if User.where.not(id: current_user.id).exists?(phone_number: phone)
      flash.now[:alert] = "That number is already in use by another account."
      return render :new, status: :unprocessable_entity
    end

    # Same number is a no-op; just redirect back to profile
    if phone == current_user.phone_number
      redirect_to edit_user_registration_path, notice: "That's already your current number."
      return
    end

    # Create OTP for current user (record tied to account), send SMS to new number
    _record, code = PhoneOtpCode.generate_for(current_user, purpose: "change_phone")
    SmsService.send_otp(to: phone, code: code, purpose: "change_phone")

    session[:phone_change_phone] = phone
    flash[:notice] = "A 6-digit code has been sent to #{phone}."
    redirect_to verify_user_phone_change_path
  end

  def verify
  end

  def confirm
    new_phone = session[:phone_change_phone]

    if new_phone.blank?
      session.delete(:phone_change_phone)
      redirect_to new_user_phone_change_path, alert: "Session expired. Please try again."
      return
    end

    otp = current_user.phone_otp_codes.for_purpose("change_phone").active.last

    if otp.nil?
      flash[:alert] = "Code has expired. Please request a new one."
      redirect_to resend_user_phone_change_path
      return
    end

    if otp.verify!(params[:code].to_s.strip)
      current_user.update!(phone_number: new_phone, phone_confirmed_at: Time.current)
      session.delete(:phone_change_phone)
      redirect_to edit_user_registration_path, notice: "Your phone number has been updated."
    elsif otp.locked_out?
      flash[:alert] = "Too many incorrect attempts. Please request a new code."
      redirect_to resend_user_phone_change_path
    else
      flash.now[:alert] = "Incorrect code. Please try again."
      render :verify, status: :unprocessable_entity
    end
  end

  def resend
    new_phone = session[:phone_change_phone]

    if new_phone.blank?
      redirect_to new_user_phone_change_path, alert: "Session expired. Please try again."
      return
    end

    _record, code = PhoneOtpCode.generate_for(current_user, purpose: "change_phone")
    SmsService.send_otp(to: new_phone, code: code, purpose: "change_phone")

    flash[:notice] = "A new code has been sent."
    redirect_to verify_user_phone_change_path
  end

  private

  def require_phone_in_session
    if session[:phone_change_phone].blank?
      redirect_to new_user_phone_change_path, alert: "Please enter your new phone number first."
    end
  end

end
