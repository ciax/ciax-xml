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
        @cc=''
      end

      def add(str) # Add to check code
        @ccrange << str if @ccrange
        verbose { "Cc Add to Range Frame [#{str.inspect}]" }
        self
      end

      def mark # Check Code Start
        verbose { 'Cc Mark Range Start' }
        @ccrange = ''
        self
      end

      def set # Check Code End
        verbose { "Cc Frame [#{@ccrange.inspect}]" }
        chk = 0
        case @method
        when 'len'
          chk = @ccrange.length
        when 'bcc'
          @ccrange.each_byte { |c| chk ^= c }
        when 'sum'
          chk = @ccrange.sum(8)
        else
          Msg.cfg_err("No such CC method #{@method}")
        end
        verbose { "Cc Calc [#{@method.upcase}] -> (#{chk})" }
        @ccrange = nil
        @cc = chk.to_s
      end

      def check(cc)
        return self unless cc
        if cc == @cc
          verbose { "Cc Verify OK [#{cc}]" }
        else
          fmt = 'CC Mismatch:[%s] (should be [%s]) in [%s]'
          cc_err(format(fmt, cc, @cc, @ccrange.inspect))
        end
        self
      end

      def to_s
        @cc
      end
    end
  end
end
