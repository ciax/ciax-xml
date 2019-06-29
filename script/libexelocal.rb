#!/usr/bin/env ruby
require 'libexe'

# Integrates Command and Status
# Provides Server and Client
# Generate Internal Command
# Add Server Command to Combine Lower Layer (Stream,Frm,App)

module CIAX
  # Device Execution Engine
  #  This instance will be assinged as @eobj in other classes
  class Exe
    # Local mode
    module Local
      def self.extended(obj)
        Msg.type?(obj, Exe)
      end

      # Local operation included in ext_test, ext_driver
      # (non_client)
      def ext_local
        @post_exe_procs << proc do |_a, _s, msg|
          @sv_stat.repl(:msg, msg)
        end
        self
      end

      # UDP Listen
      def run
        return self if @opt.cl?
        require 'libserver'
        return self if is_a?(Server)
        extend(Server).ext_server
      end

      # Option handling
      def opt_mode
        @opt.drv? ? _ext_driver : _ext_test
        run if @opt.sv?
      end

      private

      # No save any data
      def _ext_test
        @mode = 'TEST'
        @stat.ext_local.ext_file
        self
      end

      # Generate and Save Data
      def _ext_driver
        @mode = 'DRV'
        @stat.ext_local.ext_file.ext_save
        self
      end
    end
  end
end
