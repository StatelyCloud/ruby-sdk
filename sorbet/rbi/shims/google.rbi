# Without these shims, Sorbet cannot infer these types
# that are dynamically loaded by ruby proto/grpc.
module Google
  module Protobuf
    class Any
    end
  end
  module Rpc
    class Status
    end
  end
end