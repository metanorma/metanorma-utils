# frozen_string_literal: true

require "asciidoctor"

# Asciidoctor 2.0.x accumulates a multi-line table cell by rebuilding the
# whole cell buffer String on every appended line
# (`parser_ctx.buffer = %(#{parser_ctx.buffer}#{line}#{LF})` in
# Asciidoctor::Parser.parse_table), so building a cell that spans N lines
# is quadratic in the bytes of the cell. Generated tables with cells that
# span tens of thousands of lines allocate ~10 GB of transient Strings
# and exceed modest memory caps before the table finishes parsing.
#
# The patch below carries the fix inside metanorma-utils: it prepends a
# corrected Asciidoctor::Parser.parse_table whose appends go through
# ParserContext#append_to_buffer, and prepends ParserContext methods that
# accumulate the cell as an Array of segments joined once at close (and
# whenever the CSV quote check needs the whole record). No String owned
# by the buffer is ever mutated, so no frozen-string workaround is
# needed, and the per-line buffer-sized String churn the GC chases is
# gone.
#
# This is also the shape the asciidoctor maintainers have stated they
# would accept upstream: in-place string mutation is barred there by
# frozen-string literals and Opal compatibility, and their stated
# solution is "an array that is later concatenated" (the comment thread
# of asciidoctor PR #4879). An upstream fix of either stated shape stands
# the prepend down (see the disarm check at the end of this file).
module Asciidoctor
  # Replaces the buffer-mutating ParserContext methods; the two stock
  # readers of the buffer (the CSV quote check and close_cell) drain the
  # pending segments into the materialized buffer and delegate upward.
  module TableCellBufferParserContextPatch
    # Appends the String to the buffer of the currently open cell as a
    # pending segment; amortized O(1) per accumulated line.
    def append_to_buffer(str)
      (@buffer_segments ||= []) << str
      nil
    end

    def skip_past_delimiter(pre)
      (@buffer_segments ||= []) << pre << @delimiter
      nil
    end

    def skip_past_escaped_delimiter(pre)
      (@buffer_segments ||= []) << pre.chop << @delimiter
      nil
    end

    def buffer_has_unclosed_quotes?(append = nil, q = '"')
      drain_buffer_segments
      super
    end

    def close_cell(eol = false)
      drain_buffer_segments
      super
    end

    private

    # Materializes the pending segments onto the buffer String the stock
    # methods read. Cost is proportional to the pending segments only;
    # close_cell drains once per cell, and the quote check drains at most
    # once per check - the same order as the stock check's own copy of
    # the full record ((@buffer + append).strip).
    def drain_buffer_segments
      (@buffer_segments ||= []).empty? and return
      @buffer = @buffer + @buffer_segments.join
      @buffer_segments.clear
      nil
    end
  end

  module TableCellBufferPatch
  def parse_table(table_reader, parent, attributes)
    table = Table.new(parent, attributes)

    if (attributes.key? 'cols') && !(colspecs = parse_colspecs attributes['cols']).empty?
      table.create_columns colspecs
      explicit_colspecs = true
    end

    skipped = table_reader.skip_blank_lines || 0
    if attributes['header-option']
      table.has_header_option = true
    elsif skipped == 0 && !attributes['noheader-option']
      # NOTE: assume table has header until we know otherwise; if it doesn't (nil), cells in first row get reprocessed
      table.has_header_option = :implicit
      implicit_header = true
    end
    parser_ctx = Table::ParserContext.new table_reader, table, attributes
    format, loop_idx, implicit_header_boundary = parser_ctx.format, -1, nil

    while (line = table_reader.read_line)
      if (beyond_first = (loop_idx += 1) > 0) && line.empty?
        line = nil
        implicit_header_boundary += 1 if implicit_header_boundary
      elsif format == 'psv'
        if parser_ctx.starts_with_delimiter? line
          line = line.slice 1, line.length
          # push empty cell spec if cell boundary appears at start of line
          parser_ctx.close_open_cell
          implicit_header_boundary = nil if implicit_header_boundary
        else
          next_cellspec, line = parse_cellspec line, :start, parser_ctx.delimiter
          # if cellspec is not nil, we're at a cell boundary
          if next_cellspec
            parser_ctx.close_open_cell next_cellspec
            implicit_header_boundary = nil if implicit_header_boundary
          # otherwise, the cell continues from previous line
          elsif implicit_header_boundary && implicit_header_boundary == loop_idx
            table.has_header_option = implicit_header = implicit_header_boundary = nil
          end
        end
      end

      unless beyond_first
        table_reader.mark
        # NOTE implicit header is offset by at least one blank line; implicit_header_boundary tracks size of gap
        if implicit_header
          if table_reader.has_more_lines? && table_reader.peek_line.empty?
            implicit_header_boundary = 1
          else
            table.has_header_option = implicit_header = nil
          end
        end
      end

      # this loop is used for flow control; internal logic controls how many times it executes
      while true
        if line && (m = parser_ctx.match_delimiter line)
          pre_match, post_match = m.pre_match, m.post_match
          case format
          when 'csv'
            if parser_ctx.buffer_has_unclosed_quotes? pre_match
              parser_ctx.skip_past_delimiter pre_match
              break if (line = post_match).empty?
              redo
            end
            parser_ctx.append_to_buffer pre_match
          when 'dsv'
            if pre_match.end_with? '\\'
              parser_ctx.skip_past_escaped_delimiter pre_match
              if (line = post_match).empty?
                parser_ctx.append_to_buffer LF
                parser_ctx.keep_cell_open
                break
              end
              redo
            end
            parser_ctx.append_to_buffer pre_match
          else # psv
            if pre_match.end_with? '\\'
              parser_ctx.skip_past_escaped_delimiter pre_match
              if (line = post_match).empty?
                parser_ctx.append_to_buffer LF
                parser_ctx.keep_cell_open
                break
              end
              redo
            end
            next_cellspec, cell_text = parse_cellspec pre_match
            parser_ctx.push_cellspec next_cellspec
            parser_ctx.append_to_buffer cell_text
          end
          # don't break if empty to preserve empty cell found at end of line (see issue #1106)
          line = nil if (line = post_match).empty?
          parser_ctx.close_cell
        else
          # no other delimiters to see here; suck up this line into the buffer and move on
          parser_ctx.append_to_buffer %(#{line}#{LF})
          case format
          when 'csv'
            if parser_ctx.buffer_has_unclosed_quotes?
              table.has_header_option = implicit_header = implicit_header_boundary = nil if implicit_header_boundary && loop_idx == 0
              parser_ctx.keep_cell_open
            else
              parser_ctx.close_cell true
            end
          when 'dsv'
            parser_ctx.close_cell true
          else # psv
            parser_ctx.keep_cell_open
          end
          break
        end
      end

      # NOTE cell may already be closed if table format is csv or dsv
      if parser_ctx.cell_open?
        parser_ctx.close_cell true unless table_reader.has_more_lines?
      else
        table_reader.skip_blank_lines || break
      end
    end

    parser_ctx.close_table
    table.assign_column_widths unless (table.attributes['colcount'] ||= table.columns.size) == 0 || explicit_colspecs
    table.has_header_option = true if implicit_header
    table.partition_header_footer attributes

    table
  end
  end

  class Table
    class ParserContext
      prepend TableCellBufferParserContextPatch
    end
  end
end

module Metanorma
  module Utils
    module AsciidoctorTableBuffer
      # Resolved once, before the prepend: once our parse_table is in
      # place, Parser.method(:parse_table) resolves to the prepended copy
      # and its source_location points at this file, not asciidoctor's.
      PARSER_FILE = ::Asciidoctor::Parser
        .method(:parse_table).source_location.to_a.first

      class << self
        def apply!
          return false unless defined?(::Asciidoctor::VERSION)
          return true if applied?

          parser_file = PARSER_FILE
          return false unless parser_file && File.file?(parser_file)
          # Stand down once asciidoctor fixes the quadratic rebuild
          # itself, in either shape: appending in place
          # (append_to_buffer), or accumulating lines in an Array
          # joined at close - the shape the asciidoctor maintainers
          # have stated is acceptable upstream (string mutation is
          # barred there by frozen-string literals and Opal
          # compatibility; see the comment thread of asciidoctor PR
          # #4879). Detecting both matters: this patch prepends a whole
          # copy of parse_table, so shadowing an upstream fix with a
          # stale copy would silently revert their behavior.
          parser_src = File.read(parser_file)
          return false if parser_src.include?("append_to_buffer")
          return false unless parser_src.include?('parser_ctx.buffer = %(#{parser_ctx.buffer')

          ::Asciidoctor::Parser.singleton_class
            .prepend(::Asciidoctor::TableCellBufferPatch)
          ::Asciidoctor::Table::ParserContext
            .prepend(::Asciidoctor::TableCellBufferParserContextPatch)
          @applied = true
        end

        def applied?
          @applied ||= false
        end
      end
    end
  end
end

Metanorma::Utils::AsciidoctorTableBuffer.apply!
