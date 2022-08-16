require "asciidoctor"
require "tempfile"
require "sterile"
require "htmlentities"
require "nokogiri"

module Metanorma
  module Utils
    class << self
      def attr_code(attributes)
        attributes.compact.transform_values do |v|
          v.is_a?(String) ? HTMLEntities.new.decode(v) : v
        end
      end

      # , " => ," : CSV definition does not deal with space followed by quote
      # at start of field
      def csv_split(text, delim = ";")
        return if text.nil?

        CSV.parse_line(text&.gsub(/#{delim} "(?!")/, "#{delim}\""),
                       liberal_parsing: true,
                       col_sep: delim)&.compact&.map(&:strip)
      end

      # if the contents of node are blocks, output them to out;
      # else, wrap them in <p>
      def wrap_in_para(node, out)
        if node.blocks? then out << node.content
        else
          out.p { |p| p << node.content }
        end
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
        HTMLEntities.new.encode(
          HTMLEntities.new.decode(
            text.gsub(/ --? /, "&#8201;&#8212;&#8201;")
            .gsub(/--/, "&#8212;"),
          )
            .smart_format, :basic
        )
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
          hash[key] = if hash[key].is_a?(Array) then (hash[key] << new_val)
                      else hash[key].nil? ? new_val : [hash[key], new_val]
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

      # convert definition list term/value pair into Nokogiri XML attribute
      def dl_to_attrs(elem, dlist, name)
        e = dlist.at("./dt[text()='#{name}']") or return
        val = e.at("./following::dd/p") || e.at("./following::dd") or return
        elem[name] = val.text
      end

      # convert definition list term/value pairs into Nokogiri XML elements
      def dl_to_elems(ins, elem, dlist, name)
        a = elem.at("./#{name}[last()]")
        ins = a if a
        dlist.xpath("./dt[text()='#{name}']").each do |e|
          ins = dl_to_elems1(e, name, ins)
        end
        ins
      end

      def dl_to_elems1(term, name, ins)
        v = term.at("./following::dd")
        e = v.elements and e.size == 1 && e.first.name == "p" and v = e.first
        v.name = name
        ins.next = v
        ins.next
      end
    end
  end
end
