module Metanorma
  module Utils
    class << self
      # NOTE: It was used in methods of an eigenclass of Metanorma::Utils.
      #       Not sure if it's still used somewhere but could be.
      class Namespace
        def initialize(xmldoc)
          @namespace = xmldoc.root.namespace
        end

        def ns(path)
          return path if @namespace.nil?

          path.gsub(%r{/([a-zA-Z])}, "/xmlns:\\1")
            .gsub(%r{::([a-zA-Z])}, "::xmlns:\\1")
            .gsub(%r{\[([a-zA-Z][a-z0-9A-Z@/]* ?=)}, "[xmlns:\\1")
            .gsub(%r{\[([a-zA-Z][a-z0-9A-Z@/]*\])}, "[xmlns:\\1")
        end
      end

      def create_namespace(xmldoc)
        Namespace.new(xmldoc)
      end
    end
  end
end
