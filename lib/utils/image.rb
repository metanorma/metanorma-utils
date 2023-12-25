require "tempfile"
require "marcel"
require "base64"
require "vectory"
require_relative "namespace"

module Metanorma
  module Utils
    class << self
      def save_dataimage(uri)
        Vectory::Utils.save_dataimage(uri)
      end

      def svgmap_rewrite(xmldoc, localdirectory = "")
        Vectory::SvgMapping.new(xmldoc, localdirectory).call
      end

      def datauri(uri, local_dir = ".")
        Vectory::Utils.datauri(uri, local_dir)
      end

      def encode_datauri(path)
        Vectory::Utils.encode_datauri(path)
      end

      def datauri?(uri)
        Vectory::Utils.datauri?(uri)
      end

      def url?(url)
        Vectory::Utils.url?(url)
      end

      def absolute_path?(uri)
        Vectory::Utils.absolute_path?(uri)
      end

      def decode_datauri(uri)
        Vectory::Utils.decode_datauri(uri)
      end

      def datauri2mime(uri)
        Vectory::Utils.datauri2mime(uri)
      end
    end
  end
end
