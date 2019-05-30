#!/usr/bin/env ruby
require 'libcbasefunc'
#   returns String as message.
module CIAX
  # Command Module
  module CmdBase
    # Command db with parameter derived from Form
    class Entity < Config
      attr_reader :id, :par
      attr_accessor :msg
      # set should have :def_proc
      def initialize(spcfg, atrb = Hashx.new)
        super(spcfg)
        update(atrb)
        @par = self[:par]
        @id = self[:cid]
        verbose { "Config\n" + path }
      end

      # returns result of def_proc block (String)
      def exe_cmd(src, pri = 1)
        update(src: src, pri: pri)
        verbose { _exe_text(@id, src, pri) }
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
