# StatelyDB SDK for Ruby

This is the Ruby SDK for [StatelyDB](https://stately.cloud).

### Getting started:

##### Disclaimer:

We're still in an invite-only preview mode - if you're interested, please reach out to [preview@stately.cloud](mailto:preview@stately.cloud?subject=Early%20Access%20Program).

Begin by following our [Getting Started Guide] which will help you define, generate, and publish a DB schema so that it can be used.

##### Install the SDK

```sh
gem install statelydb
```


### Usage:

Create an authenticated client, then import your item types from your generated schema module and use the client!

```ruby
require_relative 'schema/stately'

def put_my_item
    # Create a client. This will use the environment variable
    # STATELY_ACCESS_KEY to read your access key
    client = StatelyDB::Client.new(store_id: <my-store-id>)

    # Instantiate an item from your schema
    item = StatelyDB::Types::MyItem.new(name: "Jane Doe")

    # put and get the item!
    put_result = client.put(item)
    get_result = client.get(StatelyDB::KeyPath.with("name", "Jane Doe"))
    puts put_result == get_result # true
```

---

[Getting Started Guide]: https://docs.stately.cloud/guides/getting-started/
[Defining Schema]: https://docs.stately.cloud/guides/schema/