require "uuidtools"

module Metanorma
  module Utils
    # Namespace for the deterministic identifier mint: the same name
    # always produces the same UUIDv5.
    STABLE_UUID_NAMESPACE = UUIDTools::UUID.parse_raw(
      [0x8d, 0x3c, 0x51, 0x93, 0x9e, 0x0c, 0x4f, 0x4d, 0x9c, 0xa3,
       0x71, 0x9c, 0x2b, 0x4f, 0x3e, 0xd2].pack("C*")
    )

    class << self
      # A deterministic identifier: the same parts always produce the
      # same UUID. Recompiling a document must produce the same
      # element ids (isodoc#861 - the random mint made every compile's
      # HTML differ).
      def stable_uuid(*parts)
        UUIDTools::UUID
          .sha1_create(STABLE_UUID_NAMESPACE, parts.compact.join("\0"))
          .to_s
      end
    end
  end
end
