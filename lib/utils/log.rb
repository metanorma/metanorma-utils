module Metanorma
  module Utils
    class Log
      def initialize
        @log = {}
      end

      def add(category, loc, msg)
        return if @novalid

        @log[category] = [] unless @log[category]
        @log[category] << { location: current_location(loc), message: msg,
                            context: context(loc) }
        loc = loc.nil? ? "" : "(#{current_location(loc)}): "
        warn "#{category}: #{loc}#{msg}"
      end

      def current_location(node)
        if node.nil? then ""
        elsif node.is_a? String then node
        elsif node.respond_to?(:lineno) && !node.lineno.nil? &&
            !node.lineno.empty?
          "Asciidoctor Line #{'%06d' % node.lineno}"
        elsif node.respond_to?(:line) && !node.line.nil?
          "XML Line #{'%06d' % node.line}"
        elsif node.respond_to?(:id) && !node.id.nil? then "ID #{node.id}"
        else
          while !node.nil? &&
              (!node.respond_to?(:level) || node.level.positive?) &&
              (!node.respond_to?(:context) || node.context != :section)
            node = node.parent
            return "Section: #{node.title}" if node.respond_to?(:context) &&
              node&.context == :section
          end
          "??"
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

      def write(file)
        File.open(file, "w:UTF-8") do |f|
          f.puts "#{file} errors"
          @log.each_key do |key|
            f.puts "\n\n== #{key}\n\n"
            @log[key].sort_by { |a| a[:location] }.each do |n|
              write1(f, n)
            end
          end
        end
      end

      def write1(file, entry)
        loc = entry[:location] ? "(#{entry[:location]}): " : ""
        file.puts "#{loc}#{entry[:message]}"
          .encode("UTF-8", invalid: :replace, undef: :replace)
        entry[:context]&.split(/\n/)&.first(5)&.each do |l|
          file.puts "\t#{l}"
        end
      end
    end
  end
end
