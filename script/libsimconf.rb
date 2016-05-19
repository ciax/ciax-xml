#!/usr/bin/ruby
require 'libconf'
require 'libstatus'

module CIAX
  # Devide Simulator
  module Simulator
    # Simulator Common Parameters
    # Upper Conf expected: :option
    class Conf < Config
      def initialize
        super()
        _init_status
        _init_log
      end

      private

      def _init_status
        list = self[:statlist] = {}
        db = Ins::Db.new
        %w(tfp tma).each do |id|
          list[id] = App::Status.new(db.get(id)).ext_http
        end
      end

      def _init_log
        bname = File.basename($PROGRAM_NAME, '.rb')
        self[:stdlog] = open(Msg.vardir('log') + bname + '.log', 'a')
      end
    end
  end
end
