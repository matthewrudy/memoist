module Memoist
  # Memoist does not support calls with block to cached method_names
  BlocksNotSupported = Class.new(StandardError)
end
