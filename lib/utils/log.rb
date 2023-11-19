require "htmlentities"

module Metanorma
  module Utils
    class Log
      attr_writer :xml

      def initialize
        @log = {}
        @c = HTMLEntities.new
        @mapid = {}
      end

      def add(category, loc, msg)
        @novalid and return
        @log[category] ||= []
        item = create_entry(loc, msg)
        @log[category] << item
        loc = loc.nil? ? "" : "(#{current_location(loc)}): "
        suppress_display?(category, loc, msg) or
          warn "#{category}: #{loc}#{msg}"
      end

      def suppress_display?(category, _loc, _msg)
        ["Metanorma XML Syntax"].include?(category)
      end

      def create_entry(loc, msg)
        msg = msg.encode("UTF-8", invalid: :replace, undef: :replace)
        item = { location: current_location(loc),
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
          node.respond_to?(:parent) ? "ID #{node['id']}" : ""
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
          msg.sub(/^XML Line /, "").sub(/:.*$/, "")
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
          <style> pre { white-space: pre-wrap; } </style>
          </head><body><h1>#{file} errors</h1>
        HTML
      end

      def write(file)
        @filename = file.sub(".err.html", ".html")
        File.open(file, "w:UTF-8") do |f|
          f.puts log_hdr(file)
          @log.each_key { |key| write_key(f, key) }
          f.puts "</body></html>\n"
        end
      end

      def write_key(file, key)
        file.puts <<~HTML
          <h2>#{key}</h2>\n<table border="1">
          <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
          <tbody>
        HTML
        @log[key].sort_by { |a| [a[:line], a[:location], a[:message]] }
          .each do |n|
          write1(file, n)
        end
        file.puts "</tbody></table>\n"
      end

      def write1(file, entry)
        line = entry[:line]
        line = nil if line == "000000"
        loc = loc_link(entry)
        msg = break_up_long_str(entry[:message], 10, 2)
          .gsub(/`([^`]+)`/, "<code>\\1</code>")
        entry[:context] and context = entry[:context].split("\n").first(5)
          .join("\n").gsub("><", "> <")
        write_entry(file, line, loc, msg, context)
      end

      def mapid(old, new)
        @mapid[old] = new
      end

      def loc_link(entry)
        loc = entry[:location]
        loc.nil? || loc.empty? and loc = "--"
        if /^ID /.match?(loc)
          loc.sub!(/^ID /, "")
          loc = @mapid[loc] while @mapid[loc]
          url = "#{@filename}##{loc}"
        end
        loc &&= break_up_long_str(loc, 10, 2)
        url and loc = "<a href='#{url}'>#{loc}</a>"
        loc
      end

      def break_up_long_str(str, threshold, punct)
        Metanorma::Utils.break_up_long_str(str, threshold, punct)
      end

      def write_entry(file, line, loc, msg, context)
        context &&= @c.encode(break_up_long_str(context, 40, 2))
        file.print <<~HTML
          <tr><td>#{line}</td><th><code>#{loc}</code></th><td>#{msg}</td><td><pre>#{context}</pre></td></tr>
        HTML
      end
    end
  end
end
