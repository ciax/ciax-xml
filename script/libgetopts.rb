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
      ___init_optdb(optarg)
      ___set_opt(optarg[:options])
      getarg(ustr, &opt_proc)
    rescue InvalidARGS
      usage(ustr)
    end

    # Mode (Device) [prompt]
    # none : test all layers        [test]
    # -e   : drive all layers       [proc]
    # -c   : client all layers      [cl]
    # -ce  : client to lower layers [drv:cl]
    # -s   : server (test)          [test:sv]
    # -se  : server (drive)         [drv:sv]

    # Mode (Macro)
    # none : test
    # -e   : with device driver
    # -se  : server with device driver
    # -c   : client to macro server
    # -ce  : client to device server

    def cl?
      %i(h c l).any? { |k| self[k] }
    end

    def drv?
      self[:e] && true
    end

    def sv?
      self[:s] && true
    end

    def test?
      !(cl? || drv?)
    end

    def sub_opt
      opt = dup
      %i(e s).each { |k| opt.delete(k) } if cl?
      opt
    end

    def host
      (self[:h] || 'localhost') unless self[:c]
    end

    def init_layer_mod
      CIAX.const_get(@init_layer.capitalize)
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

    alias log? drv?
  end

  # Given option handling
  class GetOpts
    private

    def ___set_opt(str)
      ops = ___add_colon(str)
      ___make_usage(ops)
      ___parse(ops)
      ___set_init_layer
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
      ARGV.getopts(ops).each { |k, v| self[k.to_sym] = v }
      # Parameters after options removeal
      @argv = ARGV.shift(ARGV.length)
    rescue OptionParser::ParseError
      raise(InvalidOPT, $ERROR_INFO)
    end

    # Set @init_layer (default 'Wat')
    def ___set_init_layer
      opt = __make_exopt(@layers.keys)
      @init_layer = @layers[opt]
    end

    def ___set_view_mode
      v = __make_exopt(%i(j r))
      View.default.replace(v.to_s) if v
    end

    def __make_exopt(ary)
      ary.find { |c| self[c] } || ary.find { |c| @defopt.include?(c.to_s) }
    end
  end

  # Option DB Setting
  class GetOpts
    private

    def ___init_optdb(optarg)
      ___optdb_custom(optarg)
      ___optdb_client
      ___optdb_system
      ___optdb_view
      ___optdb_layer
    end

    # Custom options
    def ___optdb_custom(optarg)
      @optdb = type?(optarg, Hash).select { |k, _v| k.to_s.length == 1 }
      optarg[:options] = optarg[:options].to_s + @optdb.keys.join
    end

    # Client option
    def ___optdb_client
      db = { c: 'default', l: 'local', h: '[host]' }
      __add_optdb(db, 'client to %s')
    end

    # System mode
    def ___optdb_system
      db = { e: 'execution', s: 'server', n: 'non-stop',
             b: 'back ground', i: 'instance' }
      __add_optdb(db, '%s mode')
    end

    def ___optdb_view
      # For visual
      db = { r: 'raw', j: 'json' }
      __add_optdb(db, '%s data output')
    end

    def ___optdb_layer
      # Layer option
      @layers = { m: 'mcr', w: 'wat', f: 'frm', x: 'hex', a: 'app' }
      __add_optdb(@layers, '%s layer')
    end

    def __add_optdb(db, fmt)
      db.each do |k, v|
        @optdb[k] = format(fmt, v)
      end
    end
  end
end
