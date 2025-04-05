require "objspace"

module Metanorma
  module Utils
    module Debug
      def self.count_objects()
        gc.start
        puts "live nokogiri::xml::document count: #{objectspace.each_object(nokogiri::xml::document).count}"
      end

      def self.dump_memory_usage
        GC.start
        objs = ObjectSpace.count_objects
        obj_cnt = objs[:TOTAL] - objs[:FREE]
        mem_size = ObjectSpace.memsize_of_all / 1024 / 1024
        puts "Memory used: #{mem_size}, obj count: #{obj_cnt}"
      end
    end
  end
end
