require "asciidoctor"
require "tempfile"
require "sterile"
require "uuidtools"
require "marcel"
require "mime/types"
require "base64"

module Metanorma
  module Utils
      NAMECHAR = "\u0000-\u0022\u0024\u002c\u002f\u003a-\u0040\\u005b-\u005e"\
        "\u0060\u007b-\u00b6\u00b8-\u00bf\u00d7\u00f7\u037e\u2000-\u200b"\
        "\u200e-\u203e\u2041-\u206f\u2190-\u2bff\u2ff0-\u3000".freeze
      #"\ud800-\uf8ff\ufdd0-\ufdef\ufffe-\uffff".freeze
      NAMESTARTCHAR = "\\u002d\u002e\u0030-\u0039\u00b7\u0300-\u036f"\
        "\u203f-\u2040".freeze

    class << self
      def to_ncname(s)
        start = s[0]
        ret1 = %r([#{NAMECHAR}#]).match(start) ? "_" :
          (%r([#{NAMESTARTCHAR}#]).match(start) ? "_#{start}" : start)
        ret2 = s[1..-1] || ""
        ret = (ret1 || "") + ret2.gsub(%r([#{NAMECHAR}#]), "_")
        ret
      end

      def anchor_or_uuid(node = nil)
        uuid = UUIDTools::UUID.random_create
        node.nil? || node.id.nil? || node.id.empty? ? "_" + uuid : node.id
      end

      def asciidoc_sub(x, flavour = :standoc)
        return nil if x.nil?
        return "" if x.empty?
        d = Asciidoctor::Document.new(x.lines.entries, { header_footer: false, backend: flavour })
        b = d.parse.blocks.first
        b.apply_subs(b.source)
      end

      def localdir(node)
        docfile = node.attr("docfile")
        docfile.nil? ? './' : Pathname.new(docfile).parent.to_s + '/'
      end

      # TODO needs internationalisation
      def smartformat(n)
        n.gsub(/ --? /, "&#8201;&#8212;&#8201;").
          gsub(/--/, "&#8212;").smart_format.gsub(/</, "&lt;").gsub(/>/, "&gt;")
      end

      def endash_date(elem)
        elem.traverse do |n|
          n.text? and n.replace(n.text.gsub(/\s+--?\s+/, "&#8211;").gsub(/--/, "&#8211;"))
        end
      end

      # Set hash value using keys path
      # mod from https://stackoverflow.com/a/42425884
      def set_nested_value(hash, keys, new_val)
        key = keys[0]
        if keys.length == 1
          hash[key] = hash[key].is_a?(Array) ?  (hash[key] << new_val) :
            hash[key].nil? ?  new_val : [hash[key], new_val]
        else
          if hash[key].is_a?(Array)
            hash[key][-1] = {} if !hash[key].empty? && hash[key][-1].nil?
            hash[key] << {} if hash[key].empty? || !hash[key][-1].is_a?(Hash)
            set_nested_value(hash[key][-1], keys[1..-1], new_val)
          elsif hash[key].nil? || hash[key].empty?
            hash[key] = {}
            set_nested_value(hash[key], keys[1..-1], new_val)
          elsif hash[key].is_a?(Hash) && !hash[key][keys[1]]
            set_nested_value(hash[key], keys[1..-1], new_val)
          elsif !hash[key][keys[1]]
            hash[key] = [hash[key], {}]
            set_nested_value(hash[key][-1], keys[1..-1], new_val)
          else
            set_nested_value(hash[key], keys[1..-1], new_val)
          end
        end
        hash
      end

      class Namespace
        def initialize(xmldoc)
          @namespace = xmldoc.root.namespace
        end

        def ns(path)
          return path if @namespace.nil?
          path.gsub(%r{/([a-zA-z])}, "/xmlns:\\1").
            gsub(%r{::([a-zA-z])}, "::xmlns:\\1").
            gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]* ?=)}, "[xmlns:\\1").
            gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]*\])}, "[xmlns:\\1")
        end
      end

      def save_dataimage(uri)
        %r{^data:(image|application)/(?<imgtype>[^;]+);base64,(?<imgdata>.+)$} =~ uri
        imgtype.sub!(/\+[a-z0-9]+$/, '') # svg+xml
        imgtype = 'png' unless /^[a-z0-9]+$/.match imgtype
        Tempfile.open(['image', ".#{imgtype}"]) do |f|
          f.binmode
          f.write(Base64.strict_decode64(imgdata))
          f.path
        end
      end

      SVG_NS = "http://www.w3.org/2000/svg".freeze

      def svgmap_rewrite(xmldoc, localdirectory = "")
        n = Namespace.new(xmldoc)
        xmldoc.xpath(n.ns("//svgmap")).each do |s|
          next unless svgmap_rewrite0(s, n, localdirectory)
          next if s.at(n.ns("./target/eref"))
          s.replace(s.at(n.ns("./figure")))
        end
      end

      def svgmap_rewrite0(s, n, localdirectory)
        if i = s.at(n.ns(".//image")) and src = i["src"]
          path = /^data:/.match(src) ? save_dataimage(src) : File.file?(src) ? src : localdirectory + src
          File.file?(path) or return false
          svgmap_rewrite1(s, Nokogiri::XML(File.read(path, encoding: "utf-8")), path, n)
          /^data:/.match(src) and i["src"] = datauri(path)
        elsif i = s.at(".//m:svg", "m" => SVG_NS)
          svgmap_rewrite1(s, i, nil, n)
        else
          return false
        end                 
        true
      end

      def svgmap_rewrite1(s, svg, path, n)
        targets = s.xpath(n.ns("./target")).each_with_object({}) do |t, m|
          x = t.at(n.ns("./xref")) and m[File.expand_path(t["href"])] = "##{x['target']}"
          x = t.at(n.ns("./link")) and m[File.expand_path(t["href"])] = x['target']
          t.remove if t.at(n.ns("./xref | ./link"))
        end
        svg.xpath(".//m:a", "m" => SVG_NS).each do |a|
          a["xlink:href"] and x = targets[File.expand_path(a["xlink:href"])] and a["xlink:href"] = x
          a["href"] and x = targets[File.expand_path(a["href"])] and a["href"] = x
        end
        path and File.open(path, "w", encoding: "utf-8") { |f| f.write(svg.to_xml) }
      end

      # not currently used
      def flatten_rawtext_lines(node, result)
        node.lines.each do |x|
          if node.respond_to?(:context) && (node.context == :literal || node.context == :listing)
            result << x.gsub(/</, "&lt;").gsub(/>/, "&gt;")
          else
            # strip not only HTML <tag>, and Asciidoc xrefs <<xref>>
            result << x.gsub(/<[^>]*>+/, "")
          end
        end
        result
      end

      # not currently used
      # if node contains blocks, flatten them into a single line;
      # and extract only raw text
      def flatten_rawtext(node)
        result = []
        if node.respond_to?(:blocks) && node.blocks?
          node.blocks.each { |b| result << flatten_rawtext(b) }
        elsif node.respond_to?(:lines)
          result = flatten_rawtext_lines(node, result)
        elsif node.respond_to?(:text)
          result << node.text.gsub(/<[^>]*>+/, "")
        else
          result << node.content.gsub(/<[^>]*>+/, "")
        end
        result.reject(&:empty?)
      end

      #   sources/plantuml/plantuml20200524-90467-1iqek5i.png already includes localdir
      def datauri(uri, localdirectory = ".")
        return uri if /^data:/.match(uri)
        path = %r{^([A-Z]:)?/}.match?(uri) ? uri : 
          File.exist?(uri) ? uri : File.join(localdirectory, uri)
        unless File.exist?(path)
          warn "image at #{path} not found"
          return uri
        end
        types = MIME::Types.type_for(path)
        type = types ? types.first.to_s : 'text/plain; charset="utf-8"'
        bin = File.open(path, 'rb', &:read)
        data = Base64.strict_encode64(bin)
        "data:#{type};base64,#{data}"
      end

      def datauri2mime(uri)
        %r{^data:image/(?<imgtype>[^;]+);base64,(?<imgdata>.+)$} =~ uri
        type = nil
        imgtype = "png" unless /^[a-z0-9]+$/.match imgtype
        ::Tempfile.open(["imageuri", ".#{imgtype}"]) do |file|
          type = datauri2mime1(file, imgdata)
        end
        [type]
      end

      def datauri2mime1(file, imgdata)
        type = nil
        begin
          file.binmode
          file.write(Base64.strict_decode64(imgdata))
          file.rewind
          type = Marcel::MimeType.for file
        ensure
          file.close!
        end
        type
      end
    end
  end
end
