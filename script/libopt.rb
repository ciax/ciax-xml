#!/usr/bin/env ruby
require 'libmsg'
require 'optparse'
# CIAX-XML
module CIAX
  module Opt
    # Option Check
    module Chk
      # Check first
      def cl?
        %i(h c).any? { |k| key?(k) }
      end

      def drv?
        %i(e l d).any? { |k| key?(k) }
      end

      def test?
        !cl? && !drv?
      end

      def sv?
        key?(:s) && true
      end

      def bg?
        key?(:b) && true
      end

      # For macro
      # dry run mode
      def dry?
        key?(:d) && true
      end

      def nonstop?
        key?(:n) && true
      end

      def mcr_log?
        drv? && !dry?
      end

      # Server run for git-tag
      def git_tag?
        mcr_log? && bg?
      end

      # Others
      def sub_opt
        opt = dup
        if opt.key?(:l)
          %i(s e l).each { |k| opt.delete(k) }
          opt[:c] = true
        end
        opt
      end

      def host
        self[:h]
      end

      # Get init_layer (default 'Wat') with require file
      def init_layer_mod
        key = __make_exopt(%i(m x w a f)) || :w
        name = @optdb.layers[key]
        require "lib#{name}dic"
        mod = name.capitalize
        cfg_err("No #{mod} module") unless CIAX.const_defined?(mod)
        CIAX.const_get(mod)
      end

      def getarg(ustr)
        @obj = yield(self, @argv)
        self
      rescue InvalidARGS
        usage(ustr)
      end

      def usage(ustr = @usagestr, code = 2)
        super("#{ustr}\n" + columns(@index), code)
      end

      # Shell or Command Line. Add after block.
      def cui(id = nil)
        @obj = @obj.get(id || @argv.shift) if @obj.is_a?(ExeDic)
        type?(@obj, Exe)
        if @argv.empty?
          @obj.shell
        else
          puts [@obj.exe(@argv), @obj.stat]
        end
        self
      rescue InvalidARGS
        usage
      end
    end

    # Global options
    class Get < Hash
      include Msg
      include Chk
      # Contents of optarg (Hash)
      # :options: valid option list (i.e. "afch:")
      # :default: default(implicit) option string (i.e "abc")
      # etc. : additional option db (i.e. { ? : "description" })
      attr_reader :init_layer
      def initialize(ustr = '', optarg = {}, &opt_proc)
        ustr = '(opt) ' + ustr unless optarg.empty?
        @defopt = optarg.delete(:default).to_s
        @optdb = Db.new(optarg)
        ___set_opt(optarg.delete(:options))
        getarg(ustr, &opt_proc)
      rescue InvalidARGS
        usage(ustr)
      end

      # Mode (Device) [prompt]
      # none : test all layers        [test]
      # -e   : drive all layers       [drv]
      # -c   : client all layers      [cl]
      # -l   : client to lower layers [drv:cl]
      # -s   : server

      # Mode (Macro)
      # none : test
      # -d   : dryrun (get status only)
      # -e   : with device driver
      # -c   : client to macro server
      # -l   : client to device server
      # -s   : server
      private

      def ___set_opt(str)
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

      def __make_exopt(ary)
        ary.find { |c| self[c] } || ary.find { |c| @defopt.include?(c.to_s) }
      end
    end
    # Option DB Setting
    class Db < Hash
      attr_reader :layers
      def initialize(optarg)
        optarg.each do |k, v|
          self[k] = { title: v } if k.to_s.length == 1
        end
        # Custom options
        optarg[:options] = optarg[:options].to_s + keys.join
        ___mk_optdb
      end

      def get(id)
        self[id][:title] if key?(id)
      end

      private

      # Remained Options
      #  g,i,k,m,o,p,q,t,u,w,y,z
      def ___mk_optdb
        ___optdb_client
        ___optdb_system
        ___optdb_view
        ___optdb_cui
        ___optdb_layer
        ___optdb_mcr
        ___optdb_dev
      end

      ## Common in Macro and Device
      # Client option
      def ___optdb_client
        db = { c: 'default', l: 'lower-layer', h: '[host]' }
        __add_optdb(db, 'client to %s')
      end

      # System mode
      def ___optdb_system
        db = { s: 'server', b: 'back ground', e: 'execution' }
        __add_optdb(db, '%s mode')
      end

      # For data appearance
      def ___optdb_view
        db = { r: 'raw', j: 'json', v: 'csv' }
        __add_optdb(db, '%s data output')
      end

      # For input interface (Shell or Command Line)
      def ___optdb_cui
        db = { i: 'interactive' }
        __add_optdb(db, '%s mode')
      end

      ## For Macro
      def ___optdb_mcr
        db = { d: 'dryrun', n: 'non-stop' }
        __add_optdb(db, '%s mode')
      end

      ## For Device
      def ___optdb_dev
        db = { t: '[key=val,..]' }
        __add_optdb(db, 'test conditions %s')
      end

      # Layer option
      def ___optdb_layer
        @layers = { w: 'wat', f: 'frm', x: 'hex', a: 'app' }
        __add_optdb(@layers, '%s layer')
      end

      def __add_optdb(db, fmt)
        db.each do |k, v|
          self[k] = { title: format(fmt, v) } unless key?(k)
        end
      end
    end
  end
end
