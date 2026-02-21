require "tempfile"
require_relative "tempfile_config"

module Metanorma
  module Utils
    # A drop-in replacement for Ruby's Tempfile class that respects
    # debug mode configuration.
    #
    # This class inherits from Ruby's standard Tempfile and provides
    # identical functionality. However, when debug mode is enabled via
    # TempfileConfig, it prevents temporary files from being deleted,
    # allowing them to be inspected for debugging purposes.
    #
    # In normal mode (debug=false), behaves exactly like Tempfile.
    # In debug mode (debug=true), files are created but never deleted.
    #
    # @example Basic usage (same as Tempfile)
    #   file = Metanorma::Utils::Tempfile.new("prefix")
    #   file.write("content")
    #   file.close
    #   # File will be deleted unless debug mode is enabled
    #
    # @example Using with a block
    #   Metanorma::Utils::Tempfile.open("prefix") do |file|
    #     file.write("content")
    #   end
    #   # File will be deleted unless debug mode is enabled
    #
    # @example Enable debug mode to preserve temp files
    #   Metanorma::Utils::TempfileConfig.debug = true
    #   file = Metanorma::Utils::Tempfile.new("debug")
    #   file.write("preserved content")
    #   file.close
    #   # File will NOT be deleted and can be inspected
    class Tempfile < ::Tempfile
      # Unlink (delete) the temporary file.
      #
      # In debug mode, this method becomes a no-op and the file is preserved.
      # In normal mode, behaves like the standard Tempfile#unlink.
      #
      # @return [nil] in debug mode, or the result of super in normal mode
      def unlink
        return if TempfileConfig.debug?

        super
      end

      # Delete the temporary file.
      #
      # This is an alias for unlink. In debug mode, this method becomes
      # a no-op and the file is preserved. In normal mode, behaves like
      # the standard Tempfile#delete.
      #
      # @return [nil] in debug mode, or the result of super in normal mode
      def delete
        return if TempfileConfig.debug?

        super
      end

      # Close the temporary file.
      #
      # In debug mode, this method always calls super with false to prevent
      # deletion, even if unlink_now is true. In normal mode, behaves like
      # the standard Tempfile#close.
      #
      # @param unlink_now [Boolean] whether to delete the file immediately
      # @return [nil]
      def close(unlink_now = false)
        if TempfileConfig.debug?
          super(false) # Never delete in debug mode
        else
          super
        end
      end
    end
  end
end
