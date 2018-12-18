#!/usr/bin/ruby
require 'libconf'

module CIAX
  # Devide Simulator
  module Simulator
    # Simulator Common Parameters
    # Upper Conf expected: :option
    class Conf < Config
      def initialize
        super()
        ___init_log
        # :mask_loaded is mask mode: true:loaded, false:stored
        self[:dev_dic] = Hashx.new
      end

      private

      def ___init_log
        bname = File.basename($PROGRAM_NAME, '.rb')
        self[:stdlog] = open(Msg.vardir('log') + bname + '.log', 'a')
      end
    end
  end
end
