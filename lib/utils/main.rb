module Metanorma
  module Utils
    class << self
      NAMECHAR = "\u0000-\u0022\u0024\u002c\u002f\u003a-\u0040\\u005b-\u005e"\
        "\u0060\u007b-\u00b6\u00b8-\u00bf\u00d7\u00f7\u037e\u2000-\u200b"\
        "\u200e-\u203e\u2041-\u206f\u2190-\u2bff\u2ff0-\u3000".freeze
      #"\ud800-\uf8ff\ufdd0-\ufdef\ufffe-\uffff".freeze
      NAMESTARTCHAR = "\\u002d\u002e\u0030-\u0039\u00b7\u0300-\u036f"\
        "\u203f-\u2040".freeze

      def to_ncname(s)
        start = s[0]
        ret1 = %r([#{NAMECHAR}#]).match(start) ? "_" :
          (%r([#{NAMESTARTCHAR}#]).match(start) ? "_#{start}" : start)
        ret2 = s[1..-1] || ""
        ret = (ret1 || "") + ret2.gsub(%r([#{NAMECHAR}#]), "_")
        ret
      end

    end
  end
end
