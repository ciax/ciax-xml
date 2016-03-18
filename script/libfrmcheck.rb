#!/usr/bin/ruby
require 'libmsg'

module CIAX
  # Frame Layer
  module Frm
    # Check Code
    class CheckCode
      include Msg
      def initialize(ccmethod)
        @method = ccmethod
        @ccrange = nil
        @checkcode = ''
      end

      def add(str) # Add to check code
        @ccrange << str if @ccrange
        verbose { "Cc Add to Range Frame [#{str.inspect}]" }
        self
      end

      def enclose
        verbose { 'Cc Mark Range Start' }
        @ccrange = ''
        yield self
        verbose { "Cc Frame [#{@ccrange.inspect}]" }
        @checkcode = _calcurate.to_s
        verbose { "Cc Calc [#{@method.upcase}] -> (#{@checkcode})" }
        @ccrange = nil
        self
      end

      def check(cc)
        return self unless cc
        if cc == @checkcode
          verbose { "Cc Verify OK [#{cc}]" }
        else
          fmt = 'CC Mismatch:[%s] (should be [%s]) in [%s]'
          cc_err(format(fmt, cc, @checkcode, @ccrange.inspect))
        end
        self
      end

      def to_s
        @checkcode
      end

      private

      def _calcurate # Check Code End
        method("cc_#{@method}").call
      rescue NameError
        Msg.cfg_err("No such CC method #{@method}")
      end

      def cc_len
        @ccrange.length
      end

      def cc_bcc
        chk = 0
        @ccrange.each_byte { |c| chk ^= c }
        chk
      end

      def cc_sum
        @ccrange.sum(8)
      end
    end
  end
end
