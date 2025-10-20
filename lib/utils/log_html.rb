module Metanorma
  module Utils
    class Log
      def to_ncname(tag)
        ::Metanorma::Utils.to_ncname(tag)
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
        @log[key].sort_by { |a| [a[:line], a[:location], a[:error]] }
          .each do |n|
          write_entry(file, render_preproc_entry(n))
        end
        file.puts "</tbody></table>\n"
      end

      def render_preproc_entry(entry)
        ret = entry.dup
        ret[:line] = nil if ret[:line] == "000000"
        ret[:location] = loc_link(entry)
        ret[:error] = break_up_long_str(entry[:error], 10, 2)
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
          <td>#{entry[:error]}</td><td><pre>#{entry[:context]}</pre></td><td>#{entry[:severity]}</td></tr>
        HTML
      end
    end
  end
end
