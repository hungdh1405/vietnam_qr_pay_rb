# frozen_string_literal: true

# Bundler provides the standard gem build/release tasks.
require "bundler/gem_tasks"
require "rake/testtask"

# Keep the repository test surface explicit: everything under test/ ending in _test.rb.
Rake::TestTask.new(:test) do |test|
  test.libs << "test"
  test.pattern = "test/**/*_test.rb"
  test.warning = true
end

task default: :test
