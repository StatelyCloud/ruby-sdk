# frozen_string_literal: true

require "rspec"
require "spec_helper"
require_relative "../../../lib/common/auth/auth0_token_provider"
require "async"
require "benchmark"

RSpec.describe "Auth0TokenProvider" do
  it "explodes when no credentials are passed" do
    expect do
      StatelyDB::Common::Auth::Auth0TokenProvider.new
    end.to raise_error(KeyError)
  end

  it "fetches a token as expected" do
    call_count = 0
    stub_request(:any,
                 "https://oauth.stately.cloud/oauth/token").to_return_json(body: lambda {
                                                                                   sleep(2) # simulate a slow request
                                                                                   call_count += 1
                                                                                   { access_token: "fresh-token-#{call_count}",
                                                                                     expires_in: 1 }
                                                                                 })

    # first run a benchmark on the ctor to check that the initial refresh doesn't block
    provider = nil
    construction_time_secs = Benchmark.realtime do
      provider = StatelyDB::Common::Auth::Auth0TokenProvider.new(client_id: "test-id",
                                                                 client_secret: "test-secret")
    end
    expect(construction_time_secs).to be < 1
    expect(provider).not_to be_nil

    # now check that the token has been fetched once
    expect(provider.get_token).to eql("fresh-token-1")
    # getting again should return the same cached token
    expect(provider.get_token).to eql("fresh-token-1")
  ensure
    provider.close
  end

  it "dedupes concurrent refreshes" do
    call_count = 0
    stub_request(:any,
                 "https://oauth.stately.cloud/oauth/token").to_return_json(body: lambda {
                                                                                   sleep(1) # simulate a slow request
                                                                                   call_count += 1
                                                                                   { access_token: "fresh-token-#{call_count}",
                                                                                     expires_in: 1 }
                                                                                 })
    provider = StatelyDB::Common::Auth::Auth0TokenProvider.new(client_id: "test-id",
                                                               client_secret: "test-secret")
    threads = []
    100.times do
      threads << Thread.new do
        expect(provider.get_token).to eql("fresh-token-1")
      end
      threads.each(&:join)
    end
  ensure
    provider.close
  end

  it "schedules background refresh correctly" do
    call_count = 0
    stub_request(:any,
                 "https://oauth.stately.cloud/oauth/token").to_return_json(body: lambda {
                                                                                   call_count += 1
                                                                                   { access_token: "test-token",
                                                                                     expires_in: 1 }
                                                                                 })
    provider = StatelyDB::Common::Auth::Auth0TokenProvider.new(client_id: "test-id",
                                                               client_secret: "test-secret")
    expect(provider.get_token).to eql("test-token")
    expect(call_count).to be(1)
    sleep(2)
    expect(call_count).to be > 1
  ensure
    provider.close
  end

  it "propagates errors correctly" do
    stub_request(:any, "https://oauth.stately.cloud/oauth/token").to_return(status: [500, "Internal Server Error"])
    provider = StatelyDB::Common::Auth::Auth0TokenProvider.new(client_id: "test-id",
                                                               client_secret: "test-secret")
    expect { provider.get_token }.to raise_exception(RuntimeError) do |e|
      expect(e.message).to eql("Auth request failed")
    end
  ensure
    provider.close
  end

  it "overrides the expiry if force flag is set" do
    #  set a really long token expiry
    call_count = 0
    stub_request(:any,
                 "https://oauth.stately.cloud/oauth/token").to_return_json(body: lambda {
                                                                                   call_count += 1
                                                                                   { access_token: "test-token-#{call_count}",
                                                                                     expires_in: 50_000 }
                                                                                 })

    provider = StatelyDB::Common::Auth::Auth0TokenProvider.new(client_id: "test-id",
                                                               client_secret: "test-secret")
    # get the token with long expiry to populate the cache
    expect(provider.get_token).to eql("test-token-1")
    # get the token again to verify the cache
    expect(provider.get_token).to eql("test-token-1")
    # now force a refresh. it should return a new token
    expect(provider.get_token(force: true)).to eql("test-token-2")
  ensure
    provider.close
  end

  it "blocks all new requests after a force" do
    #  set a really long token expiry
    call_count = 0
    delay_secs = 0
    stub_request(:any,
                 "https://oauth.stately.cloud/oauth/token").to_return_json(body: lambda {
                                                                                   call_count += 1
                                                                                   sleep(delay_secs)
                                                                                   { access_token: "test-token-#{call_count}",
                                                                                     expires_in: 50_000 }
                                                                                 })

    provider = StatelyDB::Common::Auth::Auth0TokenProvider.new(client_id: "test-id",
                                                               client_secret: "test-secret")
    # get the token with long expiry to populate the cache
    expect(provider.get_token).to eql("test-token-1")
    # get the token again to verify the cache
    expect(provider.get_token).to eql("test-token-1")
    # now set a longer delay force a refresh on a background thread
    delay_secs = 2
    t = Thread.new do
      expect(provider.get_token(force: true)).to eql("test-token-2")
    end
    # sleep a little bit so we know the background request is running
    sleep(1)
    # now try to get the token again. it should block until the background request is done
    expect(provider.get_token).to eql("test-token-2")
    t.join
  ensure
    provider.close
  end
end
