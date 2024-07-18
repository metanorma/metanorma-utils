module Metanorma
  module Utils
    module Array
      def stringify_all_keys
        map do |v|
          case v
          when ::Hash, ::Array
            v.stringify_all_keys
          else
            v
          end
        end
      end

      def symbolize_all_keys
        map do |v|
          case v
          when ::Hash, ::Array
            v.symbolize_all_keys
          else
            v
          end
        end
      end
    end
  end
end

module Metanorma
  module Utils
    module Hash
      def stringify_all_keys
        result = {}
        each do |k, v|
          result[k.to_s] = case v
                           when ::Hash, ::Array
                             v.stringify_all_keys
                           else
                             v
                           end
        end
        result
      end

      def symbolize_all_keys
        result = {}
        each do |k, v|
          result[k.to_sym] = case v
                             when ::Hash, ::Array
                               v.symbolize_all_keys
                             else
                               v
                             end
        end
        result
      end

      def deep_merge(second)
        merger = proc { |_, v1, v2|
          if ::Hash === v1 && ::Hash === v2
            v1.merge(v2, &merger)
          elsif ::Array === v1 && ::Array === v2
            v1 | v2
          elsif [:undefined].include?(v2)
            v1
          else
            v2
          end
        }
        merge(second.to_h, &merger)
      end
    end
  end
end
