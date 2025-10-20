require "htmlentities"
require_relative "log_html"

module Metanorma
  module Utils
    class Log
      attr_writer :xml, :suppress_log

      # messages: hash of message IDs to {error, severity, category}
      # severity: 0: abort; 1: serious; 2: not serious; 3: info only
      def initialize(messages = {})
        @log = {}
        @c = HTMLEntities.new
        @mapid = {}
        @suppress_log = { severity: 4, category: [] }
        @msg = messages.each_value do |v|
          v[:error] = v[:error]
            .encode("UTF-8", invalid: :replace, undef: :replace)
        end
      end

      def add_msg(messages)
        @msg.merge!(messages)
      end

      def save_to(filename, dir = nil)
        dir ||= File.dirname(filename)
        new_fn = filename.sub(/\.err\.html$/, ".html")
        b = File.join(dir, File.basename(new_fn, ".*"))
        @filename = "#{b}.err.html"
        @htmlfilename = "#{b}.html"
      end

      def add_prep(id)
        id = id.to_sym
        @msg[id] or raise "Logging: Error #{id} is not defined!"
        @novalid || suppress_log?(id) and return nil
        @log[@msg[id][:category]] ||= []
        @msg[id]
      end

      def add(id, loc, display: true, params: [])
        m = add_prep(id) or return
        msg = create_entry(loc, m[:error],
                           m[:severity], params)
        @log[m[:category]] << msg
        loc = loc.nil? ? "" : "(#{current_location(loc)}): "
        suppress_display?(m[:category], loc, msg, display) or
          warn "#{m[:category]}: #{loc}#{msg[:error]}"
      end

      def abort_messages
        @log.values.each_with_object([]) do |v, m|
          v.each do |e|
            e[:severity].zero? and m << e[:error]
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

      def suppress_log?(id)
        category =  @msg[id][:category]
        category && /^Fetching /.match?(@msg[id][:error]) ||
          @suppress_log[:severity] <= @msg[id][:severity] ||
          @suppress_log[:category].include?(category)
      end

      def suppress_display?(category, _loc, _msg, display)
        ["Metanorma XML Syntax", "Relaton"].include?(category) ||
          !display
      end

      def create_entry(loc, msg, severity, params)
        interpolated = interpolate_msg(msg, params)
        item = { location: current_location(loc), severity: severity,
                 error: interpolated, context: context(loc),
                 line: line(loc, msg) }
        if item[:error].include?(" :: ")
          a = item[:error].split(" :: ", 2)
          item[:context] = a[1]
          item[:error] = a[0]
        end
        item
      end

      def interpolate_msg(msg, params)
        # Count %s placeholders in the message
        placeholder_count = msg.scan(/%s/).length
        interpolation_params = if params.empty?
                                 ::Array.new(placeholder_count, "")
                               else
                                 params
                               end
        placeholder_count.zero? ? msg : (msg % interpolation_params)
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
    end
  end
end
