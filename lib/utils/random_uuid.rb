require "securerandom"

module Metanorma
  module Utils
    # Entropy buffer for identifier generation: document compiles create
    # hundreds of thousands of random identifiers, and an OS entropy read
    # per identifier dominated compile CPU. Draw from a pooled SecureRandom
    # block instead, refilled as it drains.
    RAND_POOL_BYTES = 65_536

    @rand_pool = +""
    @rand_pool_mutex = Mutex.new

    class << self
      def random_uuid
        bytes = @rand_pool_mutex.synchronize do
          if @rand_pool.bytesize < 16
            @rand_pool = SecureRandom.random_bytes(RAND_POOL_BYTES)
          end
          @rand_pool.byteslice(0, 16)
            .tap { @rand_pool = @rand_pool.byteslice(16..) }
        end

        bytes.setbyte(6, (bytes.getbyte(6) & 0x0f) | 0x40)
        bytes.setbyte(8, (bytes.getbyte(8) & 0x3f) | 0x80)
        hex = bytes.unpack1("H32")
        "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}"
      end
    end
  end
end
