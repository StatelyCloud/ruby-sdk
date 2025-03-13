# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "statelydb"
  s.version = "0.20.2"
  s.required_ruby_version = ">= 3.3.0"
  s.licenses    = ["Apache-2.0"]
  s.summary     = "A library for interacting with StatelyDB"
  s.description = ""
  s.authors     = ["Stately Cloud, Inc."]
  s.email       = "support@stately.cloud"
  s.files       = ["README.md", "LICENSE.txt"]
  s.files << Dir.glob("lib/**/*.rb")
  s.files << Dir.glob("sig/**/*.rbs")
  s.files << Dir.glob("rbi/**/*.rbi")
  s.files.flatten!
  s.homepage = "https://docs.stately.cloud/clients/ruby/"
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
  s.add_dependency "grpc", "1.64.3"
end
