require "htmlentities"

module Metanorma
  module Utils
    # htmlentities constructs a fresh Encoder — with its encoding procs —
    # on every #encode call. Cleanup and smart-quote processing encode per
    # text node on document-scale compiles, so the rebuilds were a
    # measured hot spot. The Encoder is deterministic per (flavor,
    # instruction set) and stateless across encodes, so one encoder per
    # instruction set can be reused.
    module HTMLEntitiesEncoderCache
      def encode(source, *instructions)
        key = instructions.empty? ? [:basic] : instructions
        cache = (@metanorma_encoder_cache ||= {})
        (cache[key] ||= ::HTMLEntities::Encoder.new(@flavor, key))
          .encode(source)
      end
    end

    ::HTMLEntities.prepend(HTMLEntitiesEncoderCache)
  end
end
