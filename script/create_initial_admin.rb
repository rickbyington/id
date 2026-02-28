# frozen_string_literal: true

# Create an initial admin user if none exists.
# Used by bin/docker-entrypoint. Set ADMIN_EMAIL and ADMIN_PASSWORD in ENV, or defaults apply.
# When a password is generated, it is appended to secrets.env so it persists.

exit 0 unless User.where(admin: true).none?

email = ENV["ADMIN_EMAIL"].presence || "admin@example.com"
password = ENV["ADMIN_PASSWORD"].presence || SecureRandom.hex(16)
generated_password = ENV["ADMIN_PASSWORD"].blank?

user = User.new(
  email: email,
  password: password,
  password_confirmation: password,
  admin: true,
  first_name: "Admin",
  last_name: "User"
)
user.skip_confirmation!
user.save!

puts "Created initial admin: #{email}"

if generated_password
  secrets_file = ENV["SECRETS_FILE"].presence || Rails.root.join("storage", "secrets.env").to_s
  begin
    File.open(secrets_file, "a") do |f|
      f.puts "ADMIN_EMAIL=#{email}"
      f.puts "ADMIN_PASSWORD=#{password}"
    end
    puts "Initial admin credentials saved to #{secrets_file}"
  rescue SystemCallError => e
    puts "Initial admin password: #{password}"
    puts "(Could not write to #{secrets_file}: #{e.message})"
  end
end
