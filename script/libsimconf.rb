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
        _init_log
        self[:list] = { load: false}
      end

      private

      def _init_log
        bname = File.basename($PROGRAM_NAME, '.rb')
        self[:stdlog] = open(Msg.vardir('log') + bname + '.log', 'a')
      end
    end
  end
end
