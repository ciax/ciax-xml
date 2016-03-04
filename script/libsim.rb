#!/usr/bin/ruby
# I/O Simulator
require 'libenumx'
require 'gserver'
module CIAX
  # Device Simulater
  module Simulator
    # Simulation Server
    class Server < GServer
      def initialize(port, *args)
        super
        Thread.abort_on_exception = true
        @separator = "\n"
      end

      def serve(io = nil)
        selectio(io)
        while (str = gets.chomp)
          sleep 0.1
          print dispatch(str).to_s + $INPUT_RECORD_SEPARATOR
        end
      rescue
        warn $ERROR_INFO
      end

      private

      def selectio(io)
        return unless io
        $stdin = $stdout = io
        $/ = @separator
      end

      def dispatch(_str); end
    end
  end
end
