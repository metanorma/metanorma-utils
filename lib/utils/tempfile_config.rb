require "singleton"

module Metanorma
  module Utils
    # Singleton configuration class for controlling Tempfile behavior
    # across the Metanorma stack.
    #
    # This class provides a centralized configuration point for enabling
    # debug mode, which prevents temporary files from being deleted.
    # This is useful for debugging and troubleshooting issues in the
    # Metanorma processing pipeline.
    #
    # @example Enable debug mode from metanorma-cli
    #   Metanorma::Utils::TempfileConfig.debug = true
    #
    # @example Check if debug mode is enabled
    #   if Metanorma::Utils::TempfileConfig.debug?
    #     puts "Temporary files will be preserved"
    #   end
    class TempfileConfig
      @debug = false
      @mutex = Mutex.new

      class << self
        # Enable or disable debug mode
        #
        # When debug mode is enabled, Metanorma::Utils::Tempfile will
        # create temporary files but will not delete them at the end
        # of execution. This allows inspection of intermediate files.
        #
        # @param value [Boolean] true to enable debug mode, false to disable
        # @return [Boolean] the new debug mode setting
        def debug=(value)
          @mutex.synchronize { @debug = !!value }
        end

        # Check if debug mode is enabled
        #
        # @return [Boolean] true if debug mode is enabled
        def debug?
          @mutex.synchronize { @debug }
        end
      end
    end
  end
end
