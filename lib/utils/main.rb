require "asciidoctor"
require "tempfile"
require "sterile"
require "uuidtools"
require "htmlentities"

module Metanorma
  module Utils
    NAMECHAR = "\u0000-\u002c\u002f\u003a-\u0040\\u005b-\u005e"\
               "\u0060\u007b-\u00b6\u00b8-\u00bf\u00d7\u00f7\u037e"\
               "\u2000-\u200b"\
               "\u200e-\u203e\u2041-\u206f\u2190-\u2bff\u2ff0-\u3000".freeze
    NAMESTARTCHAR = "\\u002d\u002e\u0030-\u0039\u00b7\u0300-\u036f"\
                    "\u203f-\u2040".freeze

    class << self
      def to_ncname(tag, asciionly: true)
        asciionly and tag = HTMLEntities.new.encode(tag, :basic, :hexadecimal)
        start = tag[0]
        ret1 = if %r([#{NAMECHAR}#])o.match?(start)
                 "_"
               else
                 (%r([#{NAMESTARTCHAR}#])o.match?(start) ? "_#{start}" : start)
               end
        ret2 = tag[1..-1] || ""
        (ret1 || "") + ret2.gsub(%r([#{NAMECHAR}#])o, "_")
      end

      def anchor_or_uuid(node = nil)
        uuid = UUIDTools::UUID.random_create
        node.nil? || node.id.nil? || node.id.empty? ? "_#{uuid}" : node.id
      end

      def asciidoc_sub(text, flavour = :standoc)
        return nil if text.nil?
        return "" if text.empty?

        d = Asciidoctor::Document.new(
          text.lines.entries,
          { header_footer: false, backend: flavour },
        )
        b = d.parse.blocks.first
        b.apply_subs(b.source)
      end

      def localdir(node)
        docfile = node.attr("docfile")
        docfile.nil? ? "./" : "#{Pathname.new(docfile).parent}/"
      end

      # TODO needs internationalisation
      def smartformat(text)
        text.gsub(/ --? /, "&#8201;&#8212;&#8201;")
          .gsub(/--/, "&#8212;").smart_format.gsub(/</, "&lt;")
          .gsub(/>/, "&gt;")
      end

      def endash_date(elem)
        elem.traverse do |n|
          next unless n.text?

          n.replace(n.text.gsub(/\s+--?\s+/, "&#8211;").gsub(/--/, "&#8211;"))
        end
      end

      # Set hash value using keys path
      # mod from https://stackoverflow.com/a/42425884
      def set_nested_value(hash, keys, new_val)
        key = keys[0]
        if keys.length == 1
          hash[key] = if hash[key].is_a?(Array)
                        (hash[key] << new_val)
                      else
                        hash[key].nil? ? new_val : [hash[key], new_val]
                      end
        elsif hash[key].is_a?(Array)
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
        hash
      end

      def strict_capitalize_phrase(str)
        str.split(/ /).map do |w|
          letters = w.chars
          letters.first.upcase!
          letters.join
        end.join(" ")
      end

      def strict_capitalize_first(str)
        str.split(/ /).each_with_index.map do |w, i|
          letters = w.chars
          letters.first.upcase! if i.zero?
          letters.join
        end.join(" ")
      end

      def external_path(path)
        win = !!((RUBY_PLATFORM =~ /(win|w)(32|64)$/) ||
                 (RUBY_PLATFORM =~ /mswin|mingw/))
        if win
          path.gsub!(%{/}, "\\")
          path[/\s/] ? "\"#{path}\"" : path
        else
          path
        end
      end

      def default_script(lang)
        case lang
        when "ar", "fa" then "Arab"
        when "ur" then "Aran"
        when "ru", "bg" then "Cyrl"
        when "hi" then "Deva"
        when "el" then "Grek"
        when "zh" then "Hans"
        when "ko" then "Kore"
        when "he" then "Hebr"
        when "ja" then "Jpan"
        else
          "Latn"
        end
      end

      def rtl_script?(script)
        %w(Arab Aran Hebr).include? script
      end

      # not currently used
      def flatten_rawtext_lines(node, result)
        node.lines.each do |x|
          result << if node.respond_to?(:context) &&
              (node.context == :literal || node.context == :listing)
                      x.gsub(/</, "&lt;").gsub(/>/, "&gt;")
                    else
                      # strip not only HTML <tag>, and Asciidoc xrefs <<xref>>
                      x.gsub(/<[^>]*>+/, "")
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
    end
  end
end
