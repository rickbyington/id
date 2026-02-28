# frozen_string_literal: true

class TestDeliveriesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :require_test_mailer

  def index
    @deliveries = ActionMailer::Base.deliveries.reverse
  end

  def show
    index = params[:id].to_i
    deliveries = ActionMailer::Base.deliveries
    if index < 1 || index > deliveries.size
      redirect_to mailbox_path, alert: "Mail not found."
      return
    end
    @delivery = deliveries[deliveries.size - index]
  end

  def clear
    ActionMailer::Base.deliveries.clear
    redirect_to mailbox_path, notice: "Mailbox cleared."
  end

  private

  def require_admin!
    return if current_user.admin?

    redirect_to root_path, status: :see_other, alert: "Not allowed."
  end

  def require_test_mailer
    return if ActionMailer::Base.delivery_method == :test

    redirect_to root_path, alert: "Mailbox is only available when no SMTP is configured."
  end
end
