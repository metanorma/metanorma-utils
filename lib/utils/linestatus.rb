module Metanorma
  module Utils
    class LineStatus
      # document attribute in the middle of a document, not in a header
      attr_reader :middoc_docattr
      # block attribute associated with preformatted text, e.g. [source]
      attr_reader :is_delim
      # block delimiter for preformatted text, e.g. ====
      attr_reader :delimln
      # passthrough block delimiter
      attr_reader :pass_delim
      # passthrough block
      attr_reader :pass
      # record previous line read
      attr_reader :prev_line

      def initialize
        # process as passthrough: init = true until hit end of document header
        @pass = true
        @delim = false
        @pass_delim = false
        @delimln = ""
      end

      def process(line)
        text = line.rstrip
        text == "++++" && !@delimln and @pass = !@pass
        if @middoc_docattr && !/^:[^ :]+:($| )/.match?(text)
          @middoc_docattr = false
          @pass = false
        elsif (@is_delim && /^(--+|\*\*+|==+|__+)$/.match?(text)) ||
            (!@is_delim && !@delimln && /^-----*$|^\.\.\.\.\.*$|^\/\/\/\/\/*$/
          .match?(text))
          @delimln = text
          @pass = true
        elsif @pass_delim
          @pass = true
          @delimln = "" # end of paragraph for paragraph with [pass]
        elsif @delimln && text == @delimln
          @pass = false
          @delimln = nil
        elsif /^:[^ :]+:($| )/.match?(text) &&
            (@prev_line.empty? || @middoc_docattr)
          @pass = true
          @middoc_docattr = true
        end
        @is_delim = /^\[(source|listing|literal|pass|comment)\b/.match?(text)
        @pass_delim = /^\[(pass)\b/.match?(text)
        @prev_line = text.strip
      end
    end
  end
end
