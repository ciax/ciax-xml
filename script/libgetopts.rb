#!/usr/bin/ruby
require 'libmsg'
require 'optparse'
# CIAX-XML
module CIAX
  # Global options
  class GetOpts < Hash
    include Msg
    # Contents of optarg (Hash)
    # :options: valid option list (i.e. "afch:")
    # :default: default(implicit) option string (i.e "abc")
    # etc. : additional option db (i.e. { ? : "description" })
    attr_reader :init_layer
    def initialize(ustr = '', optarg = {}, &opt_proc)
      ustr = '(opt) ' + ustr unless optarg.empty?
      @defopt = optarg[:default].to_s
      @optdb = OptDb.new(optarg)
      ___set_opt(optarg[:options])
      getarg(ustr, &opt_proc)
    rescue InvalidARGS
      usage(ustr)
    end

    # Mode (Device) [prompt]
    # none : test all layers        [test]
    # -e   : drive all layers       [drv]
    # -c   : client all layers      [cl]
    # -l   : client to lower layers [drv:cl]
    # -s   : shell

    # Mode (Macro)
    # none : test
    # -d   : dryrun (get status only)
    # -e   : with device driver
    # -c   : client to macro server
    # -l   : client to device server
    # -s   : shell
    private

    def ___set_opt(str)
      ops = ___add_colon(str)
      ___make_usage(ops)
      ___parse(ops)
      ___set_view_mode
    end

    # add ':' to taking parameter options whose description includes '[]'
    def ___add_colon(str)
      str.split(//).map do |k|
        k + (@optdb[k.to_sym].to_s.include?('[') ? ':' : '')
      end.join
    end

    # Make usage text
    def ___make_usage(ops)
      @index = {}
      @available = (ops.chars.map(&:to_sym) & @optdb.keys)
      # Current Options
      @available.each { |c| @index["-#{c}"] = @optdb[c] }
    end

    # ARGV must be taken after parse def ___parse(ops)
    def ___parse(ops)
      ARGV.getopts(ops).each { |k, v| self[k.to_sym] = v if v }
      # Parameters after options removeal
      @argv = ARGV.shift(ARGV.length)
    rescue OptionParser::ParseError
      raise(InvalidOPT, $ERROR_INFO)
    end

    def ___set_view_mode
      v = __make_exopt(%i(j r))
      View.default_view.replace(v.to_s) if v
    end

    def __make_exopt(ary)
      ary.find { |c| self[c] } || ary.find { |c| @defopt.include?(c.to_s) }
    end
    # Option Check
    module OptChk
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

      def sh?
        key?(:s) && true
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
        key = __make_exopt(%i(x w a f)) || :w
        name = @optdb.layers[key]
        require "lib#{name}dic"
        mod = name.capitalize
        cfg_err("No #{mod} module") unless CIAX.const_defined?(mod)
        CIAX.const_get(mod)
      end

      def getarg(ustr)
        yield(self, @argv)
        self
      rescue InvalidARGS
        usage(ustr)
      end

      def usage(ustr = @usagestr, code = 2)
        super("#{ustr}\n" + columns(@index), code)
      end
    end

    include OptChk

    # Option DB Setting
    class OptDb < Hash
      attr_reader :layers
      def initialize(optarg)
        super[optarg.select { |k, _v| k.to_s.length == 1 }]
        # Custom options
        optarg[:options] = optarg[:options].to_s + keys.join
        ___mk_optdb
      end

      def ___mk_optdb
        ___optdb_client
        ___optdb_system
        ___optdb_motion
        ___optdb_view
        ___optdb_layer
      end

      # Client option
      def ___optdb_client
        db = { c: 'default', l: 'lower-layer', h: '[host]' }
        __add_optdb(db, 'client to %s')
      end

      # System mode
      def ___optdb_system
        db = { s: 'shell', b: 'back ground' }
        __add_optdb(db, '%s mode')
      end

      # Motion mode
      def ___optdb_motion
        db = { e: 'execution', d: 'dryrun', n: 'non-stop' }
        __add_optdb(db, '%s mode')
      end

      # For data appearance
      def ___optdb_view
        db = { r: 'raw', j: 'json' }
        __add_optdb(db, '%s data output')
      end

      # Layer option
      def ___optdb_layer
        @layers = { m: 'mcr', w: 'wat', f: 'frm', x: 'hex', a: 'app', i: 'ins' }
        __add_optdb(@layers, '%s layer')
      end

      def __add_optdb(db, fmt)
        db.each do |k, v|
          self[k] = format(fmt, v)
        end
      end
    end
  end
end
