# frozen_string_literal: true

module Admin
  class PermissionsController < BaseController
    before_action :set_permission, only: %i[ show edit update destroy ]

    def index
      @permissions = Permission.order(:name, :value)
    end

    def show
    end

    def new
      @permission = Permission.new
    end

    def create
      @permission = Permission.new(permission_params)
      if @permission.save
        redirect_to admin_permission_path(@permission), notice: "Permission was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @permission.update(permission_params)
        redirect_to admin_permission_path(@permission), notice: "Permission was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @permission.destroy
      redirect_to admin_permissions_path, notice: "Permission was successfully deleted."
    end

    private

    def set_permission
      @permission = Permission.find(params[:id])
    end

    def permission_params
      params.require(:permission).permit(:name, :value)
    end
  end
end
