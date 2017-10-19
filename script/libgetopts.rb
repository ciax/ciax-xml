#!/usr/bin/ruby
require 'libmsg'
require 'optparse'
# CIAX-XML
module CIAX
  # Global options
  class GetOpts < Hash
    include Msg
    # Contents of optarg
    # options: valid option list (i.e. "afch:")
    # default: default(implicit) option string (i.e "abc")
    # etc. : additional option db (i.e. { ? : "description" })
    attr_reader :layer
    def initialize(ustr, optarg = {}, &opt_proc)
      alias_method :log?, :drv?
      ustr = "(opt) #{ustr}" unless optarg.empty?
      _set_opt(_set_db(optarg) + _set_default(optarg))
      getarg(ustr, &opt_proc)
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

    def layer_mod
      CIAX.const_get(@layer.capitalize)
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

    private

    # ARGV must be taken after parse
    def _parse(ops)
      ARGV.getopts(ops).each { |k, v| self[k.to_sym] = v }
      @argv = ARGV.shift(ARGV.length)
    rescue OptionParser::ParseError
      raise(InvalidOPT, $ERROR_INFO)
    end

    # Returns valid options
    def _set_db(optarg)
      @optdb = _init_db
      _layer_db
      db = type?(optarg, Hash).select { |k, _v| k.to_s.length == 1 }
      @optdb.update(db)
      optarg[:options].to_s + db.keys.join
    end

    # add ':' to taking parameter options whose description includes '[]'
    def _add_colon(str)
      str.split(//).map do |k|
        k + (@optdb[k.to_sym].to_s.include?('[') ? ':' : '')
      end.join
    end

    def _set_default(optarg)
      dflt = optarg[:default].to_s
      dflt.each_char { |c| ARGV.unshift('-' + c) }
      dflt
    end

    def _set_opt(str)
      ops = _add_colon(str)
      _make_usage(ops)
      _parse(ops)
      _make_layer
      _make_vmode
    end

    def _init_db
      # Client option
      { c: 'client to default server',
        l: 'client to local', h: 'client to [host]',
        # System mode
        e: 'execution mode', s: 'server mode', n: 'non-stop mode',
        b: 'back ground mode',
        # Instance mode
        i: 'instance mode',
        # For visual
        r: 'raw data output', j: 'json data output' }
    end

    def _layer_db
      # Layer option
      @layers = { m: 'mcr', w: 'wat', f: 'frm', x: 'hex', a: 'app' }
      @layers.each { |k, v| @optdb[k] = "#{v} layer" }
    end

    # Make usage text
    def _make_usage(ops)
      @index = {}
      @available = (ops.chars.map(&:to_sym) & @optdb.keys)
      # Current Options
      @available.each { |c| @index["-#{c}"] = @optdb[c] }
    end

    # Set @layer (default 'Wat')
    def _make_layer
      opt = _make_exopt(@layers.keys)
      @layer = @layers[opt]
    end

    def _make_vmode
      v = _make_exopt(%i(j r))
      View.default.replace(v.to_s) if v
    end

    def _make_exopt(ary)
      ary.find { |c| self[c] }
    end
  end
end
