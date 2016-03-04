#!/usr/bin/ruby
require 'libmsg'
require 'optparse'
# CIAX-XML
module CIAX
  # Global options
  class GetOpts < Hash
    include Msg
    # str = valid option list (afch:)
    # db = addigional option db
    attr_reader :layer, :vmode
    def initialize(usagestr, optstr, db = {})
      usagestr = "(opt) #{usagestr}"
      _init_db(db)
      type?(optstr, String)
      _make_usage(optstr)
      _parse(optstr)
      _make_layer
      _make_vmode
      yield(self, ARGV)
      return
    rescue InvalidCMD
      usage(usagestr, 4)
    rescue InvalidID
      usage(usagestr, 3)
    rescue InvalidARGS
      usage(usagestr, 2)
    end

    def cl?
      %i(h c l).any? { |k| self[k] }
    end

    def test?
      !(self[:e] || cl?)
    end

    def log?
      self[:e]
    end

    def host
      (self[:h] || 'localhost') unless self[:c]
    end

    def usage(str, code = 2)
      super("#{str}\n" + columns(@index), code)
    end

    private

    # ARGV must be taken after parse
    def _parse(optstr)
      ARGV.getopts(optstr).each { |k, v| self[k.to_sym] = v }
    rescue OptionParser::ParseError
      raise(InvalidARGS, $ERROR_INFO)
    end

    def _init_db(db)
      @optdb = {}
      _db_layer
      _db_cli
      _db_mode
      _db_vis
      _db_mcr
      _db_sys
      @optdb.update(type?(db, Hash))
    end

    # Layer option
    def _db_layer
      @layers = {
        m: 'mcr',
        w: 'wat',
        f: 'frm',
        x: 'hex',
        a: 'app'
      }
      @layers.each { |k, v| @optdb[k] = "#{v} layer" }
      self
    end

    # Client option
    def _db_cli
      @optdb.update(
        c: 'client to default server',
        l: 'client to local',
        h: 'client to [host]'
      )
      self
    end

    # Comm to devices
    def _db_mode
      @optdb.update(
        t: 'test mode (default)',
        e: 'execution mode'
      )
      self
    end

    # System process
    def _db_sys
      @optdb.update(
        s: 'server mode',
        b: 'background mode'
      )
      self
    end

    # For visual
    def _db_vis
      @optdb.update(
        v: 'visual output (default)',
        r: 'raw data output',
        j: 'json data output'
      )
      self
    end

    # For macro
    def _db_mcr
      @optdb.update(
        i: 'interactive mode',
        n: 'non-stop mode'
      )
      self
    end

    # Make usage text
    def _make_usage(optstr)
      @index = {}
      @available = (optstr.chars.map(&:to_sym) & @optdb.keys)
      # Current Options
      @available.each do|c|
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
      @vmode = _make_exopt(%i(j r v)) || :v
      self
    end

    def _make_exopt(ary)
      ary.find { |c| self[c] }
    end
  end
end
