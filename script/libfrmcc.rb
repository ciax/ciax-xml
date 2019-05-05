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
          Msg.cfg_err('Bad CC method %s', method)
        end
        @method = method
        replace(yield self) if defined? yield
      end

      def check(str)
        return self unless str
        if str == ccc
          verbose { "Cc Verify OK [#{str}]" }
        else
          fmt = 'CC Mismatch:[%s] (should be [%s]) in [%s]'
          cc_err(fmt, str, ccc, inspect)
        end
        clear
        self
      end

      def subst(str)
        str.gsub(/\$\{cc\}/, ccc)
      end

      # Calculate Check Code
      def ccc
        verbose { cfmt('Cc Range [%S]', self) }
        res = method("_cc_#{@method}").call.to_s
        verbose { cfmt('Cc Calc [%s] -> (%02X/%d)', @method.upcase, res, res) }
        res
      rescue NameError
        Msg.cfg_err('No such CC method %s', @method)
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
      odb = { l: 'len', b: 'bcc', s: 'sum' }
      Opt::Get.new('[str]', odb) do |opt, args|
        Msg.args_err if args.empty?
        cc = CheckCode.new(odb[opt.keys.first || :b])
        cc << args.shift.to_s
        puts format('%02X/%d', cc.ccc, cc.ccc)
      end
    end
  end
end
