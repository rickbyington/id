# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = User.order(:email)
    end

    def show
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_user_path(@user), notice: "User was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_users_path, notice: "User was successfully deleted."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      list = %i[email first_name last_name admin]
      list << :password << :password_confirmation if params[:user][:password].present?
      params.require(:user).permit(list)
    end
  end
end
