# frozen_string_literal: true

module Admin
  class UserPermissionsController < BaseController
    before_action :set_user_permission, only: %i[show destroy]

    def index
      @user_permissions = UserPermission.includes(:user, :permission).order(created_at: :desc)
    end

    def show
    end

    def new
      @user_permission = UserPermission.new(user_id: params[:user_id])
      @users = User.order(:email)
      @permissions = Permission.order(:name, :value)
    end

    def create
      @user_permission = UserPermission.new(user_permission_params)
      if @user_permission.save
        redirect_to admin_user_permission_path(@user_permission), notice: "User permission was successfully created."
      else
        @users = User.order(:email)
        @permissions = Permission.order(:name, :value)
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @user_permission.destroy
      redirect_to admin_user_permissions_path, notice: "User permission was successfully deleted."
    end

    private

    def set_user_permission
      @user_permission = UserPermission.find(params[:id])
    end

    def user_permission_params
      params.require(:user_permission).permit(:user_id, :permission_id)
    end
  end
end
