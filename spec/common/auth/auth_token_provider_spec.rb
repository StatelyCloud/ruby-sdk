# frozen_string_literal: true

require "rspec"
require "spec_helper"
require_relative "../../../lib/common/auth/auth_token_provider"
require_relative "../../../lib/api/auth/get_auth_token_pb"
require "async"
require "benchmark"
require "grpc_mock/rspec"

RSpec.describe "AuthTokenProvider" do
  it "explodes when no credentials are passed" do
    expect do
      StatelyDB::Common::Auth::AuthTokenProvider.new.start
    end.to raise_error(StatelyDB::Error) do |err|
      expect(err.message).to include("Unable to find an access key")
      expect(err.stately_code).to eq("Unauthenticated")
      expect(err.code_string).to eq("Unauthenticated")
    end
  end

  it "handles lifecycle correctly" do
    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_return do |_req, _call|
      Stately::Auth::GetAuthTokenResponse.new(
        auth_token: "token", expires_in_s: 1
      )
    end

    provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key")

    # getting a token before starting should raise an error
    expect do
      StatelyDB::Common::Auth::AuthTokenProvider.new.get_token
    end.to raise_error(StatelyDB::Error) do |err|
      expect(err.message).to include("Token provider has not been started")
      expect(err.stately_code).to eq("FailedPrecondition")
      expect(err.code_string).to eq("FailedPrecondition")
    end

    # now start the provider and get a token
    provider.start
    expect(provider.get_token).to eql("token")

    # calling start again should be a no-op
    expect { provider.start }.not_to raise_error
    # now close the provider
    provider.close
    # calling close again should be a no-op
    expect { provider.close }.not_to raise_error

    # calling get_token after close should raise an error
    expect do
      provider.get_token
    end.to raise_error(StatelyDB::Error) do |err|
      expect(err.message).to include("Token provider has not been started")
      expect(err.stately_code).to eq("FailedPrecondition")
      expect(err.code_string).to eq("FailedPrecondition")
    end

    # now restart the provider
    provider.start
    expect(provider.get_token).to eql("token")
  end

  it "fetches stately token as expected" do
    call_count = 0

    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_return do |req, _call|
      expect(req.access_key).to eql "test-access-key"
      sleep(2)
      call_count += 1
      Stately::Auth::GetAuthTokenResponse.new(
        auth_token: "fresh-token-#{call_count}", expires_in_s: 1
      )
    end

    # first run a benchmark on the ctor to check that the initial refresh doesn't block
    provider = nil
    construction_time_secs = Benchmark.realtime do
      provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key")
      provider.start
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

  it "dedupes concurrent stately refreshes" do
    call_count = 0

    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_return do |_req, _call|
      sleep(1)
      call_count += 1
      Stately::Auth::GetAuthTokenResponse.new(
        auth_token: "fresh-token-#{call_count}", expires_in_s: 1
      )
    end
    provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key")
    provider.start
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

  it "schedules background stately refresh correctly" do
    call_count = 0
    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_return do |_req, _call|
      call_count += 1
      Stately::Auth::GetAuthTokenResponse.new(
        auth_token: "test-token", expires_in_s: 1
      )
    end
    provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key")
    provider.start
    expect(provider.get_token).to eql("test-token")
    expect(call_count).to be(1)
    sleep(2)
    expect(call_count).to be > 1
  ensure
    provider.close
  end

  it "propagates stately errors correctly" do
    expected_err = StandardError.new("Some error")
    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_raise(expected_err)
    provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key")
    provider.start
    expect { provider.get_token }.to raise_exception(StandardError) do |e|
      expect(e.message).to eql(expected_err.message)
    end
  ensure
    provider.close
  end

  it "retries stately errors with retryable error codes" do
    count = 0
    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_return do |_req, _call|
      count += 1
      if count == 1
        raise StatelyDB::Error.new("Some error", code: GRPC::Core::StatusCodes::UNAVAILABLE, stately_code: "Unavailable")
      end

      Stately::Auth::GetAuthTokenResponse.new(
        auth_token: "test-token", expires_in_s: 100
      )
    end
    provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key")
    provider.start
    expect(provider.get_token).to eql("test-token")
    expect(count).to be(2)
  ensure
    provider.close
  end

  it "does not retry stately errors with non-retryable error codes" do
    count = 0
    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_return do |_req, _call|
      count += 1
      raise StatelyDB::Error.new("Some error",
                                 code: GRPC::Core::StatusCodes::UNAUTHENTICATED, stately_code: "Unauthenticated")
    end
    provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key", base_retry_backoff_secs: 0)
    provider.start
    expect { provider.get_token }.to raise_exception(StatelyDB::Error) do |e|
      expect(e.message).to eql("(Unauthenticated/Unauthenticated): Some error")
    end
    # one for the initial refresh that the constructor does and one for the actual get_token call
    expect(count).to eq(2)
  ensure
    provider.close
  end

  it "retries stately errors until some maximum number of attempts" do
    count = 0
    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_return do |_req, _call|
      count += 1
      raise StatelyDB::Error.new("Some error",
                                 code: GRPC::Core::StatusCodes::UNAVAILABLE, stately_code: "Unavailable")
    end

    provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key", base_retry_backoff_secs: 0)
    provider.start
    expect { provider.get_token }.to raise_exception(StatelyDB::Error) do |e|
      expect(e.message).to eql("(Unavailable/Unavailable): Some error")
    end

    # this should be 20, 10 for the initial refresh that the constructor does and 10 for the actual get_token call
    # we do a simpler check here so that the test is rob
    expect(count).to eq(2 * StatelyDB::Common::Auth::StatelyAccessTokenFetcher::RETRY_ATTEMPTS)
  ensure
    provider.close
  end

  it "overrides the stately expiry if force flag is set" do
    #  set a really long token expiry
    call_count = 0
    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_return do |_req, _call|
      call_count += 1
      Stately::Auth::GetAuthTokenResponse.new(
        auth_token: "test-token-#{call_count}", expires_in_s: 50_000
      )
    end
    provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key")
    provider.start

    # get the token with long expiry to populate the cache
    expect(provider.get_token).to eql("test-token-1")
    # get the token again to verify the cache
    expect(provider.get_token).to eql("test-token-1")
    # now force a refresh. it should return a new token
    expect(provider.get_token(force: true)).to eql("test-token-2")
  ensure
    provider.close
  end

  it "blocks all new stately requests after a force" do
    #  set a really long token expiry
    call_count = 0
    delay_secs = 0
    GrpcMock.stub_request("/stately.auth.AuthService/GetAuthToken").to_return do |_req, _call|
      call_count += 1
      sleep(delay_secs)
      Stately::Auth::GetAuthTokenResponse.new(
        auth_token: "test-token-#{call_count}", expires_in_s: 50_000
      )
    end
    provider = StatelyDB::Common::Auth::AuthTokenProvider.new(access_key: "test-access-key")
    provider.start
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
