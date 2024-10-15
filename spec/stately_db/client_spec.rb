# frozen_string_literal: true

describe StatelyDB::Client do
  it "constructs endpoints as expected" do
    # returns the default if nothing is set
    expect(described_class.send("make_endpoint")).to eq("https://api.stately.cloud")
    # returns the passed endpoint if endpoint and region are set
    expect(described_class.send("make_endpoint", endpoint: "https://test.com", region: "test")).to eq("https://test.com")
    # returns the regional endpoint if only region is set
    expect(described_class.send("make_endpoint", region: "test")).to eq("https://test.aws.api.stately.cloud")
    # trims the aws- prefix if it is present
    expect(described_class.send("make_endpoint", region: "aws-test")).to eq("https://test.aws.api.stately.cloud")
  end
end
