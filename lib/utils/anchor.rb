require "uuidtools"
require "htmlentities"

module Metanorma
  module Utils
    class << self
      # Following XML requirements for NCName: https://www.w3.org/TR/xml-names/#NT-NCName
      BASECHAR = "A-Za-z\u{C0}-\u{D6}\u{D8}-\u{F6}\u{F8}-\u{FF}\u{100}-\u{131}\u{134}-\u{13E}" \
                 "\u{141}-\u{148}\u{14A}-\u{17E}\u{180}-\u{1C3}\u{1CD}-\u{1F0}\u{1F4}-\u{1F5}" \
                 "\u{1FA}-\u{217}\u{250}-\u{2A8}\u{2BB}-\u{2C1}\u{386}\u{388}-\u{38A}\u{38C}" \
                 "\u{38E}-\u{3A1}\u{3A3}-\u{3CE}\u{3D0}-\u{3D6}\u{3DA}\u{3DC}\u{3DE}\u{3E0}" \
                 "\u{3E2}-\u{3F3}\u{401}-\u{40C}\u{40E}-\u{44F}\u{451}-\u{45C}\u{45E}-\u{481}" \
                 "\u{490}-\u{4C4}\u{4C7}-\u{4C8}\u{4CB}-\u{4CC}\u{4D0}-\u{4EB}\u{4EE}-\u{4F5}" \
                 "\u{4F8}-\u{4F9}\u{531}-\u{556}\u{559}\u{561}-\u{586}\u{5D0}-\u{5EA}" \
                 "\u{5F0}-\u{5F2}\u{621}-\u{63A}\u{641}-\u{64A}\u{671}-\u{6B7}\u{6BA}-\u{6BE}" \
                 "\u{6C0}-\u{6CE}\u{6D0}-\u{6D3}\u{6D5}\u{6E5}-\u{6E6}\u{905}-\u{939}\u{93D}" \
                 "\u{958}-\u{961}\u{985}-\u{98C}\u{98F}-\u{990}\u{993}-\u{9A8}\u{9AA}-\u{9B0}" \
                 "\u{9B2}\u{9B6}-\u{9B9}\u{9DC}-\u{9DD}\u{9DF}-\u{9E1}\u{9F0}-\u{9F1}" \
                 "\u{A05}-\u{A0A}\u{A0F}-\u{A10}\u{A13}-\u{A28}\u{A2A}-\u{A30}\u{A32}-\u{A33}" \
                 "\u{A35}-\u{A36}\u{A38}-\u{A39}\u{A59}-\u{A5C}\u{A5E}\u{A72}-\u{A74}" \
                 "\u{A85}-\u{A8B}\u{A8D}\u{A8F}-\u{A91}\u{A93}-\u{AA8}\u{AAA}-\u{AB0}" \
                 "\u{AB2}-\u{AB3}\u{AB5}-\u{AB9}\u{ABD}\u{AE0}\u{B05}-\u{B0C}\u{B0F}-\u{B10}" \
                 "\u{B13}-\u{B28}\u{B2A}-\u{B30}\u{B32}-\u{B33}\u{B36}-\u{B39}\u{B3D}" \
                 "\u{B5C}-\u{B5D}\u{B5F}-\u{B61}\u{B85}-\u{B8A}\u{B8E}-\u{B90}\u{B92}-\u{B95}" \
                 "\u{B99}-\u{B9A}\u{B9C}\u{B9E}-\u{B9F}\u{BA3}-\u{BA4}\u{BA8}-\u{BAA}" \
                 "\u{BAE}-\u{BB5}\u{BB7}-\u{BB9}\u{C05}-\u{C0C}\u{C0E}-\u{C10}\u{C12}-\u{C28}" \
                 "\u{C2A}-\u{C33}\u{C35}-\u{C39}\u{C60}-\u{C61}\u{C85}-\u{C8C}\u{C8E}-\u{C90}" \
                 "\u{C92}-\u{CA8}\u{CAA}-\u{CB3}\u{CB5}-\u{CB9}\u{CDE}\u{CE0}-\u{CE1}" \
                 "\u{D05}-\u{D0C}\u{D0E}-\u{D10}\u{D12}-\u{D28}\u{D2A}-\u{D39}\u{D60}-\u{D61}" \
                 "\u{E01}-\u{E2E}\u{E30}\u{E32}-\u{E33}\u{E40}-\u{E45}\u{E81}-\u{E82}\u{E84}" \
                 "\u{E87}-\u{E88}\u{E8A}\u{E8D}\u{E94}-\u{E97}\u{E99}-\u{E9F}\u{EA1}-\u{EA3}" \
                 "\u{EA5}\u{EA7}\u{EAA}-\u{EAB}\u{EAD}-\u{EAE}\u{EB0}\u{EB2}-\u{EB3}\u{EBD}" \
                 "\u{EC0}-\u{EC4}\u{F40}-\u{F47}\u{F49}-\u{F69}\u{10A0}-\u{10C5}\u{10D0}-\u{10F6}" \
                 "\u{1100}\u{1102}-\u{1103}\u{1105}-\u{1107}\u{1109}\u{110B}-\u{110C}" \
                 "\u{110E}-\u{1112}\u{113C}\u{113E}\u{1140}\u{114C}\u{114E}\u{1150}" \
                 "\u{1154}-\u{1155}\u{1159}\u{115F}-\u{1161}\u{1163}\u{1165}\u{1167}\u{1169}" \
                 "\u{116D}-\u{116E}\u{1172}-\u{1173}\u{1175}\u{119E}\u{11A8}\u{11AB}" \
                 "\u{11AE}-\u{11AF}\u{11B7}-\u{11B8}\u{11BA}\u{11BC}-\u{11C2}\u{11EB}\u{11F0}" \
                 "\u{11F9}\u{1E00}-\u{1E9B}\u{1EA0}-\u{1EF9}\u{1F00}-\u{1F15}\u{1F18}-\u{1F1D}" \
                 "\u{1F20}-\u{1F45}\u{1F48}-\u{1F4D}\u{1F50}-\u{1F57}\u{1F59}\u{1F5B}\u{1F5D}" \
                 "\u{1F5F}-\u{1F7D}\u{1F80}-\u{1FB4}\u{1FB6}-\u{1FBC}\u{1FBE}\u{1FC2}-\u{1FC4}" \
                 "\u{1FC6}-\u{1FCC}\u{1FD0}-\u{1FD3}\u{1FD6}-\u{1FDB}\u{1FE0}-\u{1FEC}" \
                 "\u{1FF2}-\u{1FF4}\u{1FF6}-\u{1FFC}\u{2126}\u{212A}-\u{212B}\u{212E}" \
                 "\u{2180}-\u{2182}\u{3041}-\u{3094}\u{30A1}-\u{30FA}\u{3105}-\u{312C}" \
                 "\u{AC00}-\u{D7A3}".freeze
      IDEOGRAPHIC = "\u{4E00}-\u{9FA5}\u{3007}\u{3021}-\u{3029}".freeze
      LETTER = "#{BASECHAR}#{IDEOGRAPHIC}".freeze
      DIGIT = "0-9\u{0660}-\u{0669}\u{06F0}-\u{06F9}\u{0966}-\u{096F}\u{09E6}-\u{09EF}" \
              "\u{0A66}-\u{0A6F}\u{0AE6}-\u{0AEF}\u{0B66}-\u{0B6F}\u{0BE7}-\u{0BEF}" \
              "\u{0C66}-\u{0C6F}\u{0CE6}-\u{0CEF}\u{0D66}-\u{0D6F}\u{0E50}-\u{0E59}" \
              "\u{0ED0}-\u{0ED9}\u{0F20}-\u{0F29}".freeze
      COMBINING_CHAR = "\u{0300}-\u{0345}\u{0360}-\u{0361}\u{0483}-\u{0486}\u{0591}-\u{05A1}" \
                        "\u{05A3}-\u{05B9}\u{05BB}-\u{05BD}\u{05BF}\u{05C1}-\u{05C2}\u{05C4}" \
                        "\u{064B}-\u{0652}\u{0670}\u{06D6}-\u{06DC}\u{06DD}-\u{06DF}" \
                        "\u{06E0}-\u{06E4}\u{06E7}-\u{06E8}\u{06EA}-\u{06ED}\u{0901}-\u{0903}" \
                        "\u{093C}\u{093E}-\u{094C}\u{094D}\u{0951}-\u{0954}\u{0962}-\u{0963}" \
                        "\u{0981}-\u{0983}\u{09BC}\u{09BE}\u{09BF}\u{09C0}-\u{09C4}" \
                        "\u{09C7}-\u{09C8}\u{09CB}-\u{09CD}\u{09D7}\u{09E2}-\u{09E3}\u{0A02}" \
                        "\u{0A3C}\u{0A3E}\u{0A3F}\u{0A40}-\u{0A42}\u{0A47}-\u{0A48}" \
                        "\u{0A4B}-\u{0A4D}\u{0A70}-\u{0A71}\u{0A81}-\u{0A83}\u{0ABC}" \
                        "\u{0ABE}-\u{0AC5}\u{0AC7}-\u{0AC9}\u{0ACB}-\u{0ACD}\u{0B01}-\u{0B03}" \
                        "\u{0B3C}\u{0B3E}-\u{0B43}\u{0B47}-\u{0B48}\u{0B4B}-\u{0B4D}" \
                        "\u{0B56}-\u{0B57}\u{0B82}-\u{0B83}\u{0BBE}-\u{0BC2}\u{0BC6}-\u{0BC8}" \
                        "\u{0BCA}-\u{0BCD}\u{0BD7}\u{0C01}-\u{0C03}\u{0C3E}-\u{0C44}" \
                        "\u{0C46}-\u{0C48}\u{0C4A}-\u{0C4D}\u{0C55}-\u{0C56}\u{0C82}-\u{0C83}" \
                        "\u{0CBE}-\u{0CC4}\u{0CC6}-\u{0CC8}\u{0CCA}-\u{0CCD}\u{0CD5}-\u{0CD6}" \
                        "\u{0D02}-\u{0D03}\u{0D3E}-\u{0D43}\u{0D46}-\u{0D48}\u{0D4A}-\u{0D4D}" \
                        "\u{0D57}\u{0E31}\u{0E34}-\u{0E3A}\u{0E47}-\u{0E4E}\u{0EB1}" \
                        "\u{0EB4}-\u{0EB9}\u{0EBB}-\u{0EBC}\u{0EC8}-\u{0ECD}\u{0F18}-\u{0F19}" \
                        "\u{0F35}\u{0F37}\u{0F39}\u{0F3E}\u{0F3F}\u{0F71}-\u{0F84}" \
                        "\u{0F86}-\u{0F8B}\u{0F90}-\u{0F95}\u{0F97}\u{0F99}-\u{0FAD}" \
                        "\u{0FB1}-\u{0FB7}\u{0FB9}\u{20D0}-\u{20DC}\u{20E1}\u{302A}-\u{302F}" \
                        "\u{3099}\u{309A}".freeze
      EXTENDER = "\u{00B7}\u{02D0}\u{02D1}\u{0387}\u{0640}\u{0E46}\u{0EC6}\u{3005}" \
                 "\u{3031}-\u{3035}\u{309D}-\u{309E}\u{30FC}-\u{30FE}".freeze

      # NCName specific constants - NCName is "an XML Name, minus the :"
      # NCName = (Letter | '_') (NCNameChar)*
      NCNAME_START_CHAR = "#{LETTER}_".freeze
      NCNAME_CHAR = "#{LETTER}#{DIGIT}._\\-#{COMBINING_CHAR}#{EXTENDER}".freeze
      INVALID_NCNAME_START_REGEXP = /[^#{NCNAME_START_CHAR}]/.freeze
      INVALID_NCNAME_CHAR_REGEXP = /[^#{NCNAME_CHAR}]/.freeze
      SAFE_NCNAME_REGEXP = /\A[#{NCNAME_START_CHAR}][#{NCNAME_CHAR}]*\z/.freeze
      NCNAME_INVALID = "_".freeze

      # A utility method for escaping XML NCNames (XML Names without colons).
      #
      #   to_ncname('1 < 2 & 3')
      #   # => "1___2___3"
      #
      # It follows the requirements of the specification for NCName: https://www.w3.org/TR/xml-names/#NT-NCName
      # NCName is "an XML Name, minus the :"
      def to_ncname(name, asciionly: false)
        name, valid = to_ncname_prep(name, asciionly)
        valid and return name
        starting_char = name[0]
        starting_char.gsub!(INVALID_NCNAME_START_REGEXP, NCNAME_INVALID)
        name.size == 1 and return starting_char
        following_chars = name[1..-1]
        following_chars.gsub!(INVALID_NCNAME_CHAR_REGEXP, NCNAME_INVALID)
        following_chars.gsub!(":", NCNAME_INVALID)
        starting_char << following_chars
      end

      def to_ncname_prep(name, asciionly)
        name = name&.to_s
        name.nil? and name = ""
        asciionly and name = HTMLEntities.new.encode(name,
                                                     :basic, :hexadecimal)
        [name, name.nil? || name.empty? || name.match?(SAFE_NCNAME_REGEXP)]
      end

      def anchor_or_uuid(node = nil)
        uuid = UUIDTools::UUID.random_create
        node.nil? || node.id.nil? || node.id.empty? ? "_#{uuid}" : node.id
      end

      # all element/attribute pairs that are ID anchors in Metanorma
      def anchor_attributes(presxml: false)
        ret = [%w(annotation from), %w(annotation to), %w(callout target),
               %w(xref to), %w(eref bibitemid), %w(citation bibitemid),
               %w(xref target), %w(label for), %w(location target),
               %w(index to), %w(termsource bibitemid), %w(admonition target)]
        ret1 = [%w(fn target), %w(semx source), %w(fmt-title source),
                %w(fmt-xref to), %w(fmt-xref target), %w(fmt-eref bibitemid),
                %w(fmt-xref-label container), %w(fmt-fn-body target),
                %w(fmt-annotation-body from), %w(fmt-annotation-body to),
                %w(fmt-annotation-start source), %w(fmt-annotation-start end),
                %w(fmt-annotation-start target), %w(fmt-annotation-end source),
                %w(fmt-annotation-end start), %w(fmt-annotation-end target)]
        presxml ? ret + ret1 : ret
      end

      def guid_anchor?(id)
        /^_[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i
          .match?(id)
      end

      def contenthash(elem)
        Digest::MD5.hexdigest("#{elem.path}////#{elem.text}")
          .sub(/^(.{8})(.{4})(.{4})(.{4})(.{12})$/, "_\\1-\\2-\\3-\\4-\\5")
      end
    end
  end
end
