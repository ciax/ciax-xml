#!/usr/bin/env ruby
require 'libmsg'
require 'liboptfunc'
require 'optparse'
# CIAX-XML
module CIAX
  module Opt
    # Global options
    class Get < Hash
      include Msg
      include Func
      # Contents of optarg (Hash)
      # :options: valid option list (i.e. "afch:")
      # :default: default(implicit) option string (i.e "abc")
      # etc. : additional option db (i.e. { ? : "description" })
      attr_reader :init_layer
      def initialize(ustr = '', optarg = {}, &opt_proc)
        ustr = '(opt) ' + ustr unless optarg.empty?
        ___set_default(optarg)
        @optdb = Db.new(optarg)
        _set_opt(optarg.delete(:options))
        getarg(ustr, &opt_proc)
      rescue InvalidARGS
        usage(ustr)
      end

      def getarg(ustr)
        @obj = yield(self, @argv)
        self
      rescue InvalidARGS
        usage(ustr)
      end

      def usage(ustr = @usagestr)
        super("#{ustr}\n" + columns(@index))
      end

      # Shell or Command Line. Add after block.
      def cui
        if !interactive? && @argv.empty?
          @obj.shell
        else
          @obj = @obj.get(@argv.shift) if @obj.is_a?(ExeDic)
          @obj.batch
        end
        self
      rescue InvalidARGS
        usage
      end

      private

      def _set_opt(str)
        ops = ___add_colon(str)
        ___make_usage(ops)
        ___parse(ops)
        ___exe_opt
      end

      # add ':' to taking parameter options whose description includes '[]'
      def ___add_colon(str)
        str.split(//).map do |k|
          k + (@optdb.get(k.to_sym).to_s.include?('[') ? ':' : '')
        end.join
      end

      # Make usage text
      def ___make_usage(ops)
        @index = {}
        @available = (ops.chars.map(&:to_sym) & @optdb.keys)
        # Current Options
        @available.each { |c| @index["-#{c}"] = @optdb.get(c) }
      end

      # ARGV must be taken after parse def ___parse(ops)
      def ___parse(ops)
        ARGV.getopts(ops).each { |k, v| self[k.to_sym] = v if v }
        # Parameters after options removeal
        @argv = ARGV.shift(ARGV.length)
      rescue OptionParser::ParseError
        raise(InvalidOPT, $ERROR_INFO)
      end

      def ___exe_opt
        keys.each do |k|
          @optdb[k][:proc].call(self[k]) if @optdb[k].key?(:proc)
        end
      end

      # Pick up a specified option from limiting ary
      def ___set_default(optarg)
        @default = []
        optarg.delete(:default).to_s.each_char do |s|
          @default << s.to_sym
        end
      end

      def __any_key?(*ary)
        ary.any? { |k| key?(k) || @default.include?(k) }
      end
    end
  end
end
