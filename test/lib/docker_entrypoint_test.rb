# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class DockerEntrypointTest < ActiveSupport::TestCase
  setup do
    @tmpdir = Dir.mktmpdir("docker_entrypoint_test")
    @storage_dir = File.join(@tmpdir, "storage")
    @secrets_file = File.join(@storage_dir, "secrets.env")
    @env = {}
  end

  teardown do
    FileUtils.rm_rf(@tmpdir) if File.directory?(@tmpdir)
  end

  # --- check_storage_mount! ---

  test "check_storage_mount! returns :ok when REQUIRE_STORAGE_MOUNT is 0" do
    env = { "REQUIRE_STORAGE_MOUNT" => "0" }
    assert_equal :ok, DockerEntrypoint.check_storage_mount!(@storage_dir, env: env)
  end

  test "check_storage_mount! creates storage dir when missing" do
    env = {}
    refute File.directory?(@storage_dir)
    assert_equal :ok, DockerEntrypoint.check_storage_mount!(@storage_dir, env: env)
    assert File.directory?(@storage_dir)
  end

  test "check_storage_mount! returns :ok when dir exists and is writable and no mountinfo" do
    FileUtils.mkdir_p(@storage_dir)
    env = {}
    # On macOS /proc/self/mountinfo does not exist, so we skip mount check
    assert_equal :ok, DockerEntrypoint.check_storage_mount!(@storage_dir, env: env)
  end

  test "check_storage_mount! raises when dir is not writable" do
    FileUtils.mkdir_p(@storage_dir)
    FileUtils.chmod(0o444, @storage_dir)
    env = {}
    err = assert_raises(DockerEntrypoint::StorageCheckError) do
      DockerEntrypoint.check_storage_mount!(@storage_dir, env: env)
    end
    assert_match(/not writable/, err.message)
  ensure
    FileUtils.chmod(0o755, @storage_dir) if File.directory?(@storage_dir)
  end

  test "check_storage_mount! raises when mountinfo exists and dir is not mounted" do
    FileUtils.mkdir_p(@storage_dir)
    env = {}
    mountinfo_content = "1 2 3 4 /other 5 6 7 8 9 10\n"
    real_exist = File.method(:exist?)
    real_read = File.method(:read)
    File.stub(:exist?, ->(path) { path == "/proc/self/mountinfo" ? true : real_exist.call(path) }) do
      File.stub(:read, ->(path) { path == "/proc/self/mountinfo" ? mountinfo_content : real_read.call(path) }) do
        err = assert_raises(DockerEntrypoint::StorageCheckError) do
          DockerEntrypoint.check_storage_mount!(@storage_dir, env: env)
        end
        assert_match(/not a mounted volume/, err.message)
        assert_match(/docker run -v/, err.message)
      end
    end
  end

  test "check_storage_mount! returns :ok when mountinfo exists and dir is mounted" do
    FileUtils.mkdir_p(@storage_dir)
    env = {}
    mountinfo_content = "1 2 3 4 #{@storage_dir} 5 6 7 8 9 10\n"
    real_exist = File.method(:exist?)
    real_read = File.method(:read)
    File.stub(:exist?, ->(path) { path == "/proc/self/mountinfo" ? true : real_exist.call(path) }) do
      File.stub(:read, ->(path) { path == "/proc/self/mountinfo" ? mountinfo_content : real_read.call(path) }) do
        assert_equal :ok, DockerEntrypoint.check_storage_mount!(@storage_dir, env: env)
      end
    end
  end

  # --- ensure_secrets_file! ---

  test "ensure_secrets_file! returns :exists when file already exists" do
    FileUtils.mkdir_p(File.dirname(@secrets_file))
    File.write(@secrets_file, "EXISTING=1\n")
    assert_equal :exists, DockerEntrypoint.ensure_secrets_file!(@secrets_file, env: @env)
    assert_equal "EXISTING=1\n", File.read(@secrets_file)
  end

  test "ensure_secrets_file! creates file and returns :created when file missing" do
    refute File.file?(@secrets_file)
    assert_equal :created, DockerEntrypoint.ensure_secrets_file!(@secrets_file, env: @env)
    assert File.file?(@secrets_file)
    content = File.read(@secrets_file)
    assert_match(/\ASECRET_KEY_BASE=[a-f0-9]{128}\n/, content)
    assert_match(/JWT_SECRET=[a-f0-9]{64}\n/, content)
    assert_match(/OIDC_PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----/, content)
    assert_match(/DATABASE_ADAPTER=sqlite3/, content) # commented section
  end

  test "ensure_secrets_file! adds DATABASE_ADAPTER=sqlite3 when FIRST_RUN_DEFAULT_SQLITE set" do
    @env["FIRST_RUN_DEFAULT_SQLITE"] = "1"
    DockerEntrypoint.ensure_secrets_file!(@secrets_file, env: @env)
    content = File.read(@secrets_file)
    assert_match(/^DATABASE_ADAPTER=sqlite3\n/, content)
  end

  test "ensure_secrets_file! does not add DATABASE_ADAPTER line when FIRST_RUN_DEFAULT_SQLITE blank" do
    @env["FIRST_RUN_DEFAULT_SQLITE"] = ""
    DockerEntrypoint.ensure_secrets_file!(@secrets_file, env: @env)
    content = File.read(@secrets_file)
    refute_match(/^DATABASE_ADAPTER=sqlite3\n/, content)
  end

  # --- load_secrets_file! ---

  test "load_secrets_file! does nothing when file does not exist" do
    DockerEntrypoint.load_secrets_file!(@secrets_file, env: @env)
    assert_empty @env
  end

  test "load_secrets_file! loads key=value into env" do
    FileUtils.mkdir_p(File.dirname(@secrets_file))
    File.write(@secrets_file, "FOO=bar\nBAZ=qux\n")
    DockerEntrypoint.load_secrets_file!(@secrets_file, env: @env)
    assert_equal "bar", @env["FOO"]
    assert_equal "qux", @env["BAZ"]
  end

  test "load_secrets_file! skips comments and empty lines" do
    FileUtils.mkdir_p(File.dirname(@secrets_file))
    File.write(@secrets_file, "# comment\n\nKEY=value\n  \n# another\n")
    DockerEntrypoint.load_secrets_file!(@secrets_file, env: @env)
    assert_equal "value", @env["KEY"]
    assert_equal 1, @env.size
  end

  test "load_secrets_file! strips values" do
    FileUtils.mkdir_p(File.dirname(@secrets_file))
    File.write(@secrets_file, "X=  spaced  \n")
    DockerEntrypoint.load_secrets_file!(@secrets_file, env: @env)
    assert_equal "spaced", @env["X"]
  end

  # --- run_server_setup? ---

  test "run_server_setup? returns true when argv ends with rails and server" do
    assert DockerEntrypoint.run_server_setup?(["/path/bin/rails", "server"])
    assert DockerEntrypoint.run_server_setup?(["/path/to/rails", "server"])
  end

  test "run_server_setup? returns false when argv does not end with server" do
    refute DockerEntrypoint.run_server_setup?(["/path/bin/rails", "console"])
    refute DockerEntrypoint.run_server_setup?(["/path/bin/rails"])
  end

  test "run_server_setup? returns false when second to last is not rails" do
    refute DockerEntrypoint.run_server_setup?(["/path/bin/rake", "server"])
  end

  test "run_server_setup? returns false for empty argv" do
    refute DockerEntrypoint.run_server_setup?([])
  end

  test "run_server_setup? returns false for single element" do
    refute DockerEntrypoint.run_server_setup?(["rails"])
  end
end
