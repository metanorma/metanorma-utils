require "asciidoctor"
require "tempfile"
require "sterile"
require "htmlentities"
require "nokogiri"
require "csv"
require_relative "../sterile/sterile"
require_relative "cjk"

module Metanorma
  module Utils
    class << self
      # , " => ," : CSV definition does not deal with space followed by quote
      # at start of field
      def csv_split(text, delim = ";")
        text.nil? || text.empty? and return []
        CSV.parse_line(text.gsub(/#{delim} "(?!")/, "#{delim}\""),
                       liberal_parsing: true,
                       col_sep: delim)&.compact&.map(&:strip)
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

      # TODO needs internationalisation of quote
      def smartformat(text)
        ret = HTMLEntities.new.decode(
          text.gsub(/ --? /, "&#8201;&#8212;&#8201;")
          .gsub("--", "&#8212;"),
        )
        ret = ret.gsub(%r{(#{CJK})(["'])}o, "\\1\u200a\\2")
          .gsub(%r{(["'])(#{CJK})}o, "\\1\u200a\\2")
        ret = ret.smart_format
        ret = ret.gsub(%r{(#{CJK})\u200a}o, "\\1")
          .gsub(%r{\u200a(#{CJK})}o, "\\1")
        HTMLEntities.new.encode(ret, :basic)
      end

      def endash_date(elem)
        elem.traverse do |n|
          n.text? or next
          n.replace(n.text.gsub(/\s+--?\s+/, "&#8211;").gsub("--", "&#8211;"))
        end
      end

      # Set hash value using keys path
      # mod from https://stackoverflow.com/a/42425884
      def set_nested_value(hash, keys, new_val)
        key = keys[0]
        if keys.length == 1
          hash[key] = if hash[key].is_a?(::Array) then (hash[key] << new_val)
                      else hash[key].nil? ? new_val : [hash[key], new_val]
                      end
        elsif hash[key].is_a?(::Array)
          hash[key][-1] = {} if !hash[key].empty? && hash[key][-1].nil?
          hash[key] << {} if hash[key].empty? || !hash[key][-1].is_a?(::Hash)
          set_nested_value(hash[key][-1], keys[1..-1], new_val)
        elsif hash[key].nil? || hash[key].empty?
          hash[key] = {}
          set_nested_value(hash[key], keys[1..-1], new_val)
        elsif hash[key].is_a?(::Hash) && !hash[key][keys[1]]
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

      LONGSTR_THRESHOLD = 10
      LONGSTR_NOPUNCT = 2

      # break on punct every LONGSTRING_THRESHOLD chars, with zero width space
      # if punct fails, try break on camel case, with soft hyphen
      # break regardless every LONGSTRING_THRESHOLD * LONGSTR_NOPUNCT,
      # with soft hyphen
      def break_up_long_str(text, threshold = LONGSTR_THRESHOLD,
nopunct = LONGSTR_NOPUNCT)
        /^\s*$/.match?(text) and return text
        text.split(/(?=(?:\s|-))/).map do |w|
          if /^\s*$/.match(w) || (w.size < threshold) then w
          else
            w.scan(/.{,#{threshold}}/o).map.with_index do |w1, i|
              w1.size < threshold ? w1 : break_up_long_str1(w1, i + 1, nopunct)
            end.join
          end
        end.join
      end

      STR_BREAKUP_RE = %r{
       (?<=[=_—–\u2009→?+;]) | # break after any of these
       (?<=[,.:])(?!\d) | # break on punct only if not preceding digit
       (?<=[>])(?![>]) | # > not >->
       (?<=[\]])(?![\]]) | # ] not ]-]
       (?<=//) | # //
       (?<=[/])(?![/]) | # / not /-/
       (?<![<])(?=[<]) | # < not <-<
       (?<=\p{L})(?=[(\{\[]\p{L}) # letter and bracket, followed by letter
      }x.freeze

      CAMEL_CASE_RE = %r{
        (?<=\p{Ll}\p{Ll})(?=\p{Lu}\p{Ll}\p{Ll}) # 2 lowerc / upperc, 2 lowerc
      }x.freeze

      def break_up_long_str1(text, iteration, nopunct)
        s, separator = break_up_long_str2(text)
        if s.size == 1 # could not break up
          (iteration % nopunct).zero? and
            text += "\u00ad" # force soft hyphen
          text
        else
          s[-1] = "#{separator}#{s[-1]}"
          s.join
        end
      end

      def break_up_long_str2(text)
        s = text.split(STR_BREAKUP_RE, -1)
        separator = "\u200b"
        if s.size == 1
          s = text.split(CAMEL_CASE_RE)
          separator = "\u00ad"
        end
        [s, separator]
      end
    end
  end
end
