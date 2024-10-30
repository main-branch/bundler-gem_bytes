# frozen_string_literal: true

# In your Turnip step definitions file
require 'fileutils'
require 'process_executer'
require 'stringio'
require 'tmpdir'

# Around hook to ensure the temp directory is cleaned up
RSpec.configure do |config|
  config.around(:each, type: :feature) do |example|
    @project_dir = Dir.pwd
    Dir.mktmpdir do |temp_dir|
      @temp_dir = temp_dir
      Dir.chdir(temp_dir) do
        example.run
      end
    end
  end
end

# rubocop:disable Style/TrivialAccessors
def project_dir = @project_dir
def temp_dir = @temp_dir
def gem_project_dir = @gem_project_dir
def gem_bytes_script_name = @gem_bytes_script_name
def gem_bytes_script_path = @gem_bytes_script_path
def gemspec_path = @gemspec_path
def env = { 'BUNDLE_IGNORE_CONFIG' => 'TRUE' }
def command_out = @command_out
def command_err = @command_err
def command_status = @command_status
# rubocop:enable Style/TrivialAccessors

def run_command(command, raise_on_fail: true, failure_message: "#{command[0]} failed")
  out_buffer = StringIO.new
  out_pipe = ProcessExecuter::MonitoredPipe.new(out_buffer)
  err_buffer = StringIO.new
  err_pipe = ProcessExecuter::MonitoredPipe.new(err_buffer)

  ProcessExecuter.spawn(env, *command, timeout: 5, out: out_pipe, err: err_pipe).tap do |status|
    @command_out = out_buffer.string
    @command_err = err_buffer.string
    @command_status = status

    raise "#{failure_message}: #{command_err}" if raise_on_fail && !command_status.success?
  end
end

step 'a gem project named :gem_name with the bundler-gem_bytes plugin installed' do |gem_name|
  @gem_project_dir = File.join(temp_dir, gem_name)

  command = [
    'bundle', 'gem', gem_name, '--no-test', '--no-ci', '--no-mit', '--no-coc', '--no-linter', '--no-changelog'
  ]
  run_command(command, failure_message: 'Failed to create gem project')

  Dir.chdir(gem_project_dir) do
    command = ['bundle', 'plugin', 'install', '--path', project_dir, 'bundler-gem_bytes']
    run_command(command, failure_message: 'Failed to install plugin')
  end
end

step 'the project has a gemspec containing:' do |content|
  @gemspec_path = File.join(@gem_project_dir, "#{File.basename(gem_project_dir)}.gemspec")
  File.write gemspec_path, content
end

step 'a gem-bytes script :gem_bytes_script_name containing:' do |gem_bytes_script_name, content|
  @gem_bytes_script_name = gem_bytes_script_name
  @gem_bytes_script_path = File.join(@gem_project_dir, gem_bytes_script_name)
  File.write gem_bytes_script_path, content
end

step 'I run :command' do |command|
  Dir.chdir(gem_project_dir) do
    run_command(command.split, fail_on_error: false)
  end
end

step 'the command should have succeeded' do
  expect(command_status.success?).to eq(true)
end

step 'the command should have failed' do
  expect(command_status.success?).to eq(false)
end

step 'the gemspec should contain:' do |content|
  expect(File.read(gemspec_path)).to eq(content)
end

step 'the command stderr should contain :content' do |content|
  expect(command_err).to include(content)
end
