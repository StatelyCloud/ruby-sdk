# frozen_string_literal: true

require_relative "lib/version"
Gem::Specification.new do |s|
  s.name = "statelydb"
  s.version = StatelyDB::VERSION
  s.required_ruby_version = ">= 3.2.0"
  s.licenses    = ["Apache-2.0"]
  s.summary     = "A library for interacting with StatelyDB"
  s.description = "Client for StatelyDB, a document database built on top of DynamoDB with Elastic Schema that allows you to change your data model any time with automatic backwards compatibility." # rubocop:disable Layout/LineLength
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
  s.add_dependency "async", "~> 2.0"
  s.add_dependency "async-actor", "~> 0.1"
  s.add_dependency "async-http", "~> 0.1"
  s.add_dependency "grpc", "~> 1.0"
  # include rake because it's required to build grpc native extensions
  # and some environments may not have it installed causing grpc installation to fail.
  # Lock to 13.x.x as that's what grpc uses:
  # https://github.com/grpc/grpc/blob/a77f9ec7c0f5175ad87343c35dbb43142f3a690f/grpc.gemspec#L40
  s.add_dependency "rake", "~> 13.0"
end
