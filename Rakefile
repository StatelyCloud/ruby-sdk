# frozen_string_literal: true

require "bundler"
require "rake"

Bundler::GemHelper.install_tasks

namespace :docs do
  desc "Generate RBS types from documentation with Sord"
  task :sord do
    sh "sord sig/statelydb.rbs --no-sord-comments"
    sh "sord sig/statelydb.rbi --no-sord-comments"
  end
end
