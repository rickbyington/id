class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  has_many :user_permissions, dependent: :destroy
  has_many :permissions, through: :user_permissions

  # Check if the user has a permission by name, optionally scoped by value.
  # Examples:
  #   user.has_permission?("invoice_reader")
  #   user.has_permission?("invoices", "write")
  def has_permission?(name, value = nil)
    rel = permissions.where(name: name)
    rel = rel.where(value: value) if value.present?
    rel.exists?
  end

  # Return the value for a permission by name, or nil if not assigned.
  def permission_value(name)
    permissions.find_by(name: name)&.value
  end
end
