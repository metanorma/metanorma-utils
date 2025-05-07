require "htmlentities"

module Metanorma
  module Utils
    class Log
      attr_writer :xml, :suppress_log

      def initialize
        @log = {}
        @c = HTMLEntities.new
        @mapid = {}
        @suppress_log = { severity: 4, category: [] }
      end

      def to_ncname(tag)
        ::Metanorma::Utils.to_ncname(tag)
      end

      def save_to(filename, dir = nil)
        dir ||= File.dirname(filename)
        new_fn = filename.sub(/\.err\.html$/, ".html")
        b = File.join(dir, File.basename(new_fn, ".*"))
        @filename = "#{b}.err.html"
        @htmlfilename = "#{b}.html"
      end

      # severity: 0: abort; 1: serious; 2: not serious; 3: info only
      def add(category, loc, msg, severity: 2, display: true)
        @novalid || suppress_log?(category, severity, msg) and return
        @log[category] ||= []
        item = create_entry(loc, msg, severity)
        @log[category] << item
        loc = loc.nil? ? "" : "(#{current_location(loc)}): "
        suppress_display?(category, loc, msg, display) or
          warn "#{category}: #{loc}#{msg}"
      end

      def abort_messages
        @log.values.each_with_object([]) do |v, m|
          v.each do |e|
            e[:severity].zero? and m << e[:message]
          end
        end
      end

      def messages
        @log.values.each_with_object([]) do |v, m|
          v.each do |e|
            m << e
          end
        end
      end

      def suppress_log?(category, severity, msg)
        category == "Relaton" && /^Fetching /.match?(msg) ||
          @suppress_log[:severity] <= severity ||
          @suppress_log[:category].include?(category)
      end

      def suppress_display?(category, _loc, _msg, display)
        ["Metanorma XML Syntax", "Relaton"].include?(category) ||
          !display
      end

      def create_entry(loc, msg, severity)
        msg = msg.encode("UTF-8", invalid: :replace, undef: :replace)
        item = { location: current_location(loc), severity: severity,
                 message: msg, context: context(loc), line: line(loc, msg) }
        if item[:message].include?(" :: ")
          a = item[:message].split(" :: ", 2)
          item[:context] = a[1]
          item[:message] = a[0]
        end
        item
      end

      def current_location(node)
        if node.nil? then ""
        elsif node.respond_to?(:id) && !node.id.nil? then "ID #{node.id}"
        elsif node.respond_to?(:id) && node.id.nil? && node.respond_to?(:parent)
          while !node.nil? && node.id.nil?
            node = node.parent
          end
          node.nil? ? "" : "ID #{node.id}"
        elsif node.respond_to?(:to_xml) && node.respond_to?(:parent)
          while !node.nil? && node["id"].nil? && node.respond_to?(:parent)
            node = node.parent
          end
          node.respond_to?(:parent) ? "ID #{node['anchor'] || node['id']}" : ""
        elsif node.is_a? String then node
        elsif node.respond_to?(:lineno) && !node.lineno.nil? &&
            !node.lineno.empty?
          "Asciidoctor Line #{'%06d' % node.lineno}"
        elsif node.respond_to?(:line) && !node.line.nil?
          "XML Line #{'%06d' % node.line}"
        elsif node.respond_to?(:parent)
          while !node.nil? &&
              (!node.respond_to?(:level) || node.level.positive?) &&
              (!node.respond_to?(:context) || node.context != :section)
            node = node.parent
            return "Section: #{node.title}" if node.respond_to?(:context) &&
              node&.context == :section
          end
          "??"
        else "??"
        end
      end

      def line(node, msg)
        if node.respond_to?(:line) && !node.line.nil?
          "#{'%06d' % node.line}"
        elsif /^XML Line /.match?(msg)
          msg.sub(/^XML Line /, "").sub(/(^[^:]+):.*$/, "\\1")
        else
          "000000"
        end
      end

      def context(node)
        node.is_a? String and return nil
        node.respond_to?(:to_xml) and return human_readable_xml(node)
        node.respond_to?(:to_s) and return node.to_s
        nil
      end

      # try to approximate input, at least for maths
      def human_readable_xml(node)
        ret = node.dup
        ret.xpath(".//*[local-name() = 'stem']").each do |s|
          sub = s.at("./*[local-name() = 'asciimath'] | " \
                     "./*[local-name() = 'latexmath']")
          sub and s.replace(sub)
        end
        ret.to_xml
      end

      def log_hdr(file)
        <<~HTML
          <html><head><title>#{file} errors</title>
          <meta charset="UTF-8"/>
          <style> pre { white-space: pre-wrap; }
          thead th { font-weight: bold; background-color: aqua; }
          .severity0 { font-weight: bold; background-color: lightpink }
          .severity1 { font-weight: bold; }
          .severity2 { }
          .severity3 { font-style: italic; color: grey; }
          </style>
          </head><body><h1>#{file} errors</h1>
          <ul>#{log_index}</ul>
        HTML
      end

      def log_index
        @log.each_with_object([]) do |(k, v), m|
          m << <<~HTML
            <li><p><b><a href="##{to_ncname(k)}">#{k}</a></b>: #{index_severities(v)}</p></li>
          HTML
        end.join("\n")
      end

      def index_severities(entries)
        s = entries.each_with_object({}) do |e, m|
          m[e[:severity]] ||= 0
          m[e[:severity]] += 1
        end.compact
        s.keys.sort.map do |k|
          "Severity #{k}: <b>#{s[k]}</b> errors"
        end.join("; ")
      end

      def write(file = nil)
        (!file && @filename) or save_to(file || "metanorma", nil)
        File.open(@filename, "w:UTF-8") do |f|
          f.puts log_hdr(@filename)
          @log.each_key { |key| write_key(f, key) }
          f.puts "</body></html>\n"
        end
      end

      def write_key(file, key)
        file.puts <<~HTML
          <h2 id="#{to_ncname(key)}">#{key}</h2>\n<table border="1">
          <thead><th width="5%">Line</th><th width="20%">ID</th>
          <th width="30%">Message</th><th width="40%">Context</th><th width="5%">Severity</th></thead>
          <tbody>
        HTML
        @log[key].sort_by { |a| [a[:line], a[:location], a[:message]] }
          .each do |n|
          write_entry(file, render_preproc_entry(n))
        end
        file.puts "</tbody></table>\n"
      end

      def render_preproc_entry(entry)
        ret = entry.dup
        ret[:line] = nil if ret[:line] == "000000"
        ret[:location] = loc_link(entry)
        ret[:message] = break_up_long_str(entry[:message], 10, 2)
          .gsub(/`([^`]+)`/, "<code>\\1</code>")
        ret[:context] = context_render(entry)
        ret.compact
      end

      def context_render(entry)
        entry[:context] or return nil
        entry[:context].split("\n").first(5)
          .join("\n").gsub("><", "> <")
      end

      def mapid(old, new)
        @mapid[old] = new
      end

      def loc_link(entry)
        loc = entry[:location]
        loc.nil? || loc.empty? and loc = "--"
        loc, url = loc_to_url(loc)
        loc &&= break_up_long_str(loc, 10, 2)
        url and loc = "<a href='#{url}'>#{loc}</a>"
        loc
      end

      def loc_to_url(loc)
        /^ID /.match?(loc) or return [loc, nil]
        loc.sub!(/^ID /, "")
        loc = @mapid[loc] while @mapid[loc]
        url = "#{@htmlfilename}##{to_ncname loc}"
        [loc, url]
      end

      def break_up_long_str(str, threshold, punct)
        Metanorma::Utils.break_up_long_str(str, threshold, punct)
      end

      def write_entry(file, entry)
        entry[:context] &&= @c.encode(break_up_long_str(entry[:context], 40, 2))
        file.print <<~HTML
          <tr class="severity#{entry[:severity]}">
          <td>#{entry[:line]}</td><th><code>#{entry[:location]}</code></th>
          <td>#{entry[:message]}</td><td><pre>#{entry[:context]}</pre></td><td>#{entry[:severity]}</td></tr>
        HTML
      end
    end
  end
end
