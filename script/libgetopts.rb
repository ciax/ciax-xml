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
    attr_reader :layer
    def initialize(usagestr, optstr, db = {})
      _init_db(db)
      type?(optstr, String)
      _make_usage(optstr)
      parse(optstr)
      _make_layer
      yield(self)
    rescue InvalidARGS
      usage("(opt) #{usagestr}")
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

    def usage(str)
      super("#{str}\n" + columns(@index))
    end

    # ARGV must be taken after parse
    def parse(optstr)
      given = ARGV.select { |s| s =~ /-/ }
      ARGV.getopts(optstr).each { |k, v| self[k.to_sym] = v }
    rescue OptionParser::ParseError
      raise(InvalidARGS, "Invalid Option #{given}")
    end

    private

    def _init_db(db)
      @optdb = type?(db, Hash)
      _db_layer
      _db_cli
      _db_mode
      _db_vis
      _db_mcr
      _db_sys
    end

    # Layer option
    def _db_layer
      @optdb.update(
        m: 'mcr layer',
        w: 'wat layer',
        a: 'app layer(default)',
        f: 'frm layer',
        x: 'hex layer'
      )
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
        d: 'delete process',
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
      lopt = %i(m x a f w).find { |c| self[c] } || :a
      @layer = @optdb[lopt].split(' ').first
      self
    end
  end
end
