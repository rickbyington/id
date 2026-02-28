# frozen_string_literal: true

# Logic for bin/docker-entrypoint: storage check, secrets generation, loading secrets.
# Extracted for unit testing. The entrypoint script calls these and then execs.

require "securerandom"
require "openssl"
require "fileutils"

module DockerEntrypoint
  class StorageCheckError < StandardError; end

  # Check that storage dir exists, is writable, and (on Linux) is a mount point.
  # Returns :ok or raises StorageCheckError with message. Set env["REQUIRE_STORAGE_MOUNT"] = "0" to skip.
  # mountinfo_path: optional path to mountinfo file (for tests); default /proc/self/mountinfo when present.
  def self.check_storage_mount!(storage_dir, env: ENV, mountinfo_path: "/proc/self/mountinfo")
    return :ok if env["REQUIRE_STORAGE_MOUNT"] == "0"

    FileUtils.mkdir_p(storage_dir) unless File.directory?(storage_dir)
    unless File.writable?(storage_dir)
      raise StorageCheckError, "#{storage_dir} is not writable. Fix permissions or run with -v."
    end

    return :ok unless File.exist?(mountinfo_path)

    mounted = File.read(mountinfo_path).lines.any? do |line|
      fields = line.split
      fields[4] == storage_dir  # 5th field is mount point per mountinfo(5)
    end
    unless mounted
      raise StorageCheckError,
        "#{storage_dir} is not a mounted volume. Data would be lost when the container stops. " \
        "Run with: docker run -v /path/to/storage:#{storage_dir} ... (or use make run)"
    end
    :ok
  end

  # Generate secrets file if missing. Returns :created or :exists.
  def self.ensure_secrets_file!(secrets_file, env: ENV)
    return :exists if File.file?(secrets_file)

    secrets_dir = File.dirname(secrets_file)
    FileUtils.mkdir_p(secrets_dir)
    oidc_pem = OpenSSL::PKey::RSA.new(2048).to_pem
    oidc_pem_escaped = oidc_pem.gsub("\n", "\\n")

    File.open(secrets_file, "a") do |f|
      f.puts "SECRET_KEY_BASE=#{SecureRandom.hex(64)}"
      f.puts "JWT_SECRET=#{SecureRandom.hex(32)}"
      f.puts "OIDC_PRIVATE_KEY=#{oidc_pem_escaped}"
      f.puts "DATABASE_ADAPTER=sqlite3" if env["FIRST_RUN_DEFAULT_SQLITE"].to_s != ""
      f.puts ""
      f.puts "# Database: use sqlite3 (standalone) or postgresql. Uncomment one:"
      f.puts "# DATABASE_ADAPTER=sqlite3"
      f.puts "# DATABASE_ADAPTER=postgresql"
      f.puts ""
      f.puts "# PostgreSQL (when DATABASE_ADAPTER=postgresql). Uncomment and set:"
      f.puts "# DATABASE_HOST=localhost          # PostgreSQL host"
      f.puts "# DATABASE_PORT=5432               # PostgreSQL port"
      f.puts "# DATABASE_USERNAME=postgres      # PostgreSQL user"
      f.puts "# DATABASE_PASSWORD=               # PostgreSQL password (primary/cache/queue/cable in database.yml)"
      f.puts ""
      f.puts "# SMTP (outgoing email). Uncomment and set to use real delivery instead of test mailbox:"
      f.puts "# SMTP_USER_NAME=                  # SMTP username (e.g. your-smtp-user)"
      f.puts "# SMTP_PASSWORD=                   # SMTP password"
      f.puts "# SMTP_ADDRESS=smtp.example.com   # SMTP server hostname"
      f.puts "# SMTP_PORT=587                    # SMTP port (587 for TLS, 465 for SSL)"
      f.puts ""
      f.puts "# SignalWire SMS (required for phone number sign-in / sign-up):"
      f.puts "# SIGNALWIRE_PROJECT_ID=           # Project ID from SignalWire dashboard"
      f.puts "# SIGNALWIRE_API_TOKEN=            # API token from SignalWire dashboard"
      f.puts "# SIGNALWIRE_SPACE_URL=            # e.g. yourspace.signalwire.com"
      f.puts "# SIGNALWIRE_FROM_NUMBER=          # Your SignalWire phone number, e.g. +15551234567"
      f.puts ""
      f.puts "# Initial admin user (created on first run if none exists). Uncomment to set:"
      f.puts "# ADMIN_EMAIL=admin@example.com   # Default: admin@example.com"
      f.puts "# ADMIN_PASSWORD=                 # Default: random, printed in log and saved here if generated"
    end
    :created
  end

  # Load key=value lines from secrets file into env (mutates env). Skips comments and empty lines.
  # Does not overwrite keys that are already set (e.g. from docker-compose), so compose env takes precedence.
  def self.load_secrets_file!(secrets_file, env: ENV)
    return unless File.file?(secrets_file)

    File.foreach(secrets_file) do |line|
      line = line.strip
      next if line.empty? || line.start_with?("#")
      key, value = line.split("=", 2)
      next unless key
      next if env.key?(key) && !env[key].to_s.strip.empty?

      env[key] = value.to_s.strip
    end
  end

  # True if argv looks like "rails server" (e.g. ./bin/thrust ./bin/rails server).
  def self.run_server_setup?(argv)
    argv[-2]&.end_with?("rails") && argv[-1] == "server"
  end
end
