#!/usr/bin/env ruby
require 'libmsg'
require 'libfrmcodec'

module CIAX
  # Frame Layer
  module Frm
    # Check Code
    class CheckCode < String
      include Msg
      def initialize(method)
        super()
        # method [len, bcc, sum]
        unless %w(len bcc sum).include?(method)
          Msg.cfg_err("Bad CC method #{method}")
        end
        @method = method
        concat(yield self) if defined? yield
      end

      def check(str)
        return self unless str
        if str == ccc
          verbose { "Cc Verify OK [#{str}]" }
        else
          fmt = 'CC Mismatch:[%s] (should be [%s]) in [%s]'
          cc_err(format(fmt, str, ccc, inspect))
        end
        clear
        self
      end

      def subst(str)
        str.gsub(/\$\{cc\}/, ccc)
      end

      # Calculate Check Code
      def ccc
        res = method("_cc_#{@method}").call.to_s
        verbose { "Cc Calc [#{@method.upcase}] -> (#{res})" }
        res
      rescue NameError
        Msg.cfg_err("No such CC method #{@method}")
      end

      private

      def _cc_len
        length
      end

      def _cc_bcc
        chk = 0
        each_byte { |c| chk ^= c }
        chk
      end

      def _cc_sum
        sum(8)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libopt'
      Opt::Get.new('[str]') do |_opt, args|
        cc = CheckCode.new('bcc')
        cc << args.shift.to_s
        puts cc.ccc
      end
    end
  end
end
