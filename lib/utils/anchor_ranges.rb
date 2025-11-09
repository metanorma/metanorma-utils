module Metanorma
  module Utils
    # AnchorRanges provides efficient range checking for nodes based on
    # anchor positions in a document. It determines whether an arbitrary node
    # falls within the range # defined by two anchor points (A-B), where
    # the range includes node A through all descendants of node B.
    class AnchorRanges
      attr_reader :anchor_map

      # Initialize with a Nokogiri document
      # @param doc [Nokogiri::XML::Document] The document to process
      def initialize(doc)
        @anchor_map = build_anchor_id_map(doc)
        @anchor_to_ord = nil
        @anchor_to_last_ord = nil
        @id_to_ord = nil
      end

      # Get mapping of anchor to ord
      # @return [Hash] anchor => ord
      def anchor_to_ord
        @anchor_to_ord ||= build_anchor_to_ord
      end

      # Get mapping of anchor to last descendant ord
      # @return [Hash] anchor => last_ord
      def anchor_to_last_ord
        @anchor_to_last_ord ||= build_anchor_to_last_ord
      end

      # Get mapping of id to ord
      # @return [Hash] id => ord
      def id_to_ord
        @id_to_ord ||= build_id_to_ord
      end

      # Check if a node (by id or anchor) is within the range A-B
      # @param node_id_or_anchor [String] The id or anchor of the node to check
      # @param anchor_a [String] The anchor defining the start of the range
      # @param anchor_b [String] The anchor defining the end of the range
      # @return [Boolean] true if the node is within the range A-B
      def in_range?(node_id_or_anchor, anchor_a, anchor_b)
        node_ord = find_node_ord(node_id_or_anchor)
        return false if node_ord.nil?

        start_ord = anchor_to_ord[anchor_a]
        end_ord = anchor_to_last_ord[anchor_b]

        return false if start_ord.nil? || end_ord.nil?

        node_ord >= start_ord && node_ord <= end_ord
      end

      # Get the ordinal range for an anchor (start to last descendant)
      # @param anchor [String] The anchor to get the range for
      # @return [Range, nil] The range of ordinals, or nil if anchor not found
      def anchor_range(anchor)
        start_ord = anchor_to_ord[anchor]
        end_ord = anchor_to_last_ord[anchor]
        return nil if start_ord.nil? || end_ord.nil?

        (start_ord..end_ord)
      end

      private

      # Generate a map of all nodes with anchor or id attributes,
      # recording their linear order and the next non-descendant anchor
      # @return [Array<Hash>] Array of hashes with keys: :anchor, :id, :ord, :next_anchor
      def build_anchor_id_map(doc)
        nodes = doc.xpath("//*[@id or @anchor]")
        nodes.each_with_index.map do |node, i|
          {
            anchor: node["anchor"],
            id: node["id"],
            ord: i,
            next_anchor: find_next_non_descendant_anchor(nodes, i),
          }
        end
      end

      # Find the anchor attribute of the next node that is not a descendant
      # of the node at the given index
      #
      # @param nodes [Nokogiri::XML::NodeSet] All nodes with anchor or id
      # @param current_index [Integer] Index of the current node
      # @return [String, nil] The anchor attribute of the next non-descendant node
      def find_next_non_descendant_anchor(nodes, current_index)
        current_node = nodes[current_index]
        current_path = current_node.path

        # Look through subsequent nodes
        ((current_index + 1)...nodes.length).each do |i|
          next_node = nodes[i]
          next_path = next_node.path

          # Check if next_node is a descendant of current_node
          # A node is a descendant if its path starts with the current path
          # followed by a path separator
          unless next_path.start_with?("#{current_path}/")
            return next_node["anchor"]
          end
        end

        nil # No non-descendant node found
      end

      def build_anchor_to_ord
        hash = {}
        @anchor_map.each do |entry|
          hash[entry[:anchor]] = entry[:ord] if entry[:anchor]
        end
        hash
      end

      def build_id_to_ord
        hash = {}
        @anchor_map.each do |entry|
          hash[entry[:id]] = entry[:ord] if entry[:id]
        end
        hash
      end

      def build_anchor_to_last_ord
        hash = {}
        @anchor_map.each do |entry|
          next unless entry[:anchor]

          # The last descendant is the ord right before the next_anchor
          # If there's no next_anchor, it's the last node in the map
          if entry[:next_anchor]
            next_ord = anchor_to_ord[entry[:next_anchor]]
            hash[entry[:anchor]] = next_ord - 1 if next_ord
          else
            # No next anchor means this extends to the end of the document
            hash[entry[:anchor]] = @anchor_map.last[:ord]
          end
        end
        hash
      end

      def find_node_ord(node_id_or_anchor)
        # Try as anchor first, then as id
        anchor_to_ord[node_id_or_anchor] || id_to_ord[node_id_or_anchor]
      end
    end
  end
end
