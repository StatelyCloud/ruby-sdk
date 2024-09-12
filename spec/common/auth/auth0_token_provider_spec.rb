# frozen_string_literal: true

require "rspec"
require "spec_helper"
require_relative "../../../lib/common/auth/auth0_token_provider"
require "webmock/rspec"

RSpec.describe "Auth0TokenProvider" do
  it "explodes when no credentials are passed" do
    expect do
      StatelyDB::Common::Auth::Auth0TokenProvider.new
    end.to raise_error(KeyError)
  end

  it "fetches a token as expected" do
    stub_request(:any,
                 "https://oauth.stately.cloud/oauth/token").to_return_json(body: { access_token: "fresh-token",
                                                                                   expires_in: 100 })
    provider = StatelyDB::Common::Auth::Auth0TokenProvider.new(client_id: "test-id",
                                                               client_secret: "test-secret")
    expect(provider).not_to be_nil
    expect(provider.access_token).to eql("fresh-token")
  end

  it "only fetches one token at a time and doesn't refetch every time" do
    call_count = 0
    stub_request(:any,
                 "https://oauth.stately.cloud/oauth/token").to_return_json(body: lambda {
                                                                                   call_count += 1
                                                                                   { access_token: "fresh-token-#{call_count}",
                                                                                     expires_in: 100 }
                                                                                 })
    provider = StatelyDB::Common::Auth::Auth0TokenProvider.new(client_id: "test-id",
                                                               client_secret: "test-secret")
    expect(provider).not_to be_nil

    threads = []
    10.times do
      threads << Thread.new do
        expect(provider.access_token).to eql("fresh-token-1")
      end
      threads.each(&:join)
    end
  end

  it "refetches after the given interval" do
    call_count = 0
    stub_request(:any,
                 "https://oauth.stately.cloud/oauth/token").to_return_json(body: lambda {
                                                                                   call_count += 1
                                                                                   { access_token: call_count,
                                                                                     expires_in: 1 }
                                                                                 })
    provider = StatelyDB::Common::Auth::Auth0TokenProvider.new(client_id: "test-id",
                                                               client_secret: "test-secret")
    expect(provider).not_to be_nil
    expect(provider.access_token).to be(1)
    sleep(4)
    expect(provider.access_token).to be > 2
  end
end
