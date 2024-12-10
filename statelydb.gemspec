# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "statelydb"
  s.version = "0.12.1"
  s.required_ruby_version = ">= 3.3.0"
  s.licenses    = ["Apache-2.0"]
  s.summary     = "A library for interacting with StatelyDB"
  s.description = ""
  s.authors     = ["Stately Cloud, Inc."]
  s.email       = "ruby@stately.cloud"
  s.files       = ["lib/statelydb.rb", "README.md"]
  s.files << Dir.glob("lib/**/*")
  s.files.flatten!
  s.homepage = "https://stately.cloud/sdk"
  s.metadata = {
    # this blocks the publisher from publishing unless MFA is enabled on
    # their rubygems account: https://guides.rubygems.org/mfa-requirement-opt-in/
    "rubygems_mfa_required" => "true"
  }

  # Gemfile is only for development and test dependencies
  # If you want people who depend on your gem to have the deps installed
  # they have to go here
  s.add_dependency "async", "2.21.1"
  s.add_dependency "async-actor", "0.1.1"
  s.add_dependency "async-http", "0.85.0"
  s.add_dependency "grpc", "1.63.0"
end
