#!/usr/bin/ruby
require 'libmsg'
require 'optparse'
# CIAX-XML
module CIAX
  # Global options
  class GetOpts < Hash
    include Msg
    # optstr: valid option list (i.e. "afch:")
    # db: additional option db (i.e. { ? : "description" })
    # default: default option string (i.e "abc")
    attr_reader :layer
    def initialize(usagestr, optstr, db = {}, default = '', &opt_proc)
      Thread.current[:name] = 'Main'
      @usagestr = "(opt) #{usagestr}"
      optstr += db.keys.join + default
      default.each_byte { |c| self[c.to_sym] = true }
      _init_db(db)
      _set_opt(optstr)
      yield(self, ARGV) if opt_proc
    rescue InvalidARGS
      usage
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
      %i(e s).any? { |k| self[k] }
    end

    def test?
      !(cl? || drv?)
    end

    def sub_opt
      opt = dup
      %i(e s).each { |k| opt.delete(k) } if cl?
      opt
    end

    def log?
      self[:e]
    end

    def host
      (self[:h] || 'localhost') unless self[:c]
    end

    def usage(str = @usagestr, code = 2)
      super("#{str}\n" + columns(@index), code)
    end

    private

    # ARGV must be taken after parse
    def _parse(optstr)
      ARGV.getopts(optstr).each { |k, v| self[k.to_sym] = v }
    rescue OptionParser::ParseError
      raise(InvalidOPT, $ERROR_INFO)
    end

    def _init_db(db)
      @optdb = {}
      _db_layer
      _db_cli
      _db_mode
      _db_vis
      @optdb.update(type?(db, Hash))
    end

    def _set_opt(optstr)
      type?(optstr, String)
      _make_usage(optstr)
      _parse(optstr)
      _make_layer
      _make_vmode
    end

    # Layer option
    def _db_layer
      @layers = { m: 'mcr', w: 'wat', f: 'frm', x: 'hex', a: 'app' }
      @layers.each { |k, v| @optdb[k] = "#{v} layer" }
      self
    end

    # Client option
    def _db_cli
      @optdb.update(c: 'client to default server',
                    l: 'client to local', h: 'client to [host]')
      self
    end

    # System mode
    def _db_mode
      @optdb.update(
        e: 'execution mode', s: 'server mode', n: 'non-stop mode',
        b: 'back ground mode'
      )
      self
    end

    # For visual
    def _db_vis
      @optdb.update(r: 'raw data output', j: 'json data output')
      self
    end

    # Make usage text
    def _make_usage(optstr)
      @index = {}
      @available = (optstr.chars.map(&:to_sym) & @optdb.keys)
      # Current Options
      @available.each do |c|
        @index["-#{c}"] = @optdb[c]
      end
      self
    end

    # Set @layer (default 'Wat')
    def _make_layer
      opt = _make_exopt(@layers.keys)
      @layer = @layers[opt]
      self
    end

    def _make_vmode
      v = _make_exopt(%i(j r))
      View.default.replace(v.to_s) if v
      self
    end

    def _make_exopt(ary)
      ary.find { |c| self[c] }
    end
  end
end
