#!/usr/bin/ruby
require 'libconf'
# @cfg[:def_proc] should be Proc which is given |Entity| as param
#   returns String as message.
module CIAX
  # Command Module
  module CmdBase
    # Default Proc Setting method
    module CmdProc
      include Msg
      attr_reader :cfg

      # Proc should return String
      def def_proc(&def_proc)
        @cfg[:def_proc] = type?(def_proc, Proc)
        self
      end
    end

    # Command db with parameter derived from Item
    class Entity < Config
      attr_reader :id, :par
      attr_accessor :msg
      # set should have :def_proc
      def initialize(cfg, atrb = Hashx.new)
        super(cfg).update(atrb)
        @par = self[:par]
        @id = self[:cid]
        verbose { "Config\n" + path }
      end

      # returns result of def_proc block (String)
      def exe_cmd(src, pri = 1)
        verbose { "Execute [#{@id}] from #{src}" }
        ___input_log(src, pri)
        @msg = self[:def_msg] || ''
        self[:def_proc].call(self, src, pri)
        self
      end

      private

      # For input logging (returns String)
      def ___input_log(src, pri)
        input = self[:input]
        return unless input && !@id.empty?
        verbose { "Input [#{@id}] from #{src}" }
        input.update(cid: self[:cid], src: src)
        input[:pri] = pri if pri
        input.cmt
      end
    end
  end
end
