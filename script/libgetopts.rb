#!/usr/bin/ruby
require 'libmsg'
require 'optparse'
# CIAX-XML
module CIAX
  # Global options
  class GetOpts < Hash
    # str = valid option list (afch:)
    # db = addigional option db
    attr_reader :layer
    def initialize
      @optdb = {}
      make_db
    end

    def parse(str, db = {})
      Msg.type?(str, String)
      @optdb.update(db)
      optary = current_options(str, db.keys)
      make_usage(optary)
      update(_sym_key_(str))
      make_layer
    rescue OptionParser::ParseError
      raise(UserError, '')
    end

    def sv?
      %i(s e).any? { |k| self[k] }
    end

    def cl?
      %i(h c l).any? { |k| self[k] }
    end

    def test?
      !sv? && !cl?
    end

    def log?
      self[:e]
    end

    def host
      (self[:h] || 'localhost') unless self[:c]
    end

    def usage(str)
      Msg.usage(str + "\n" + Msg.columns(@index))
    end

    private

    def _sym_key_(str)
      ARGV.getopts(str).each do |k, v|
        self[k.to_sym] = v
      end
    end

    def make_db
      layer_db
      cli_db
      mode_db
      vis_db
      mcr_db
      sys_db
    end

    # Layer option
    def layer_db
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
    def cli_db
      @optdb.update(
        c: 'client to default server',
        l: 'client to local',
        h: 'client to [host]'
      )
      self
    end

    # Comm to devices
    def mode_db
      @optdb.update(
        t: 'test mode (default)',
        s: 'simulation mode',
        e: 'execution mode'
      )
      self
    end

    # System process
    def sys_db
      @optdb.update(
        d: 'delete process',
        b: 'background mode'
      )
      self
    end

    # For visual
    def vis_db
      @optdb.update(
        v: 'visual output (default)',
        r: 'raw data output',
        j: 'json data output'
      )
      self
    end

    # For macro
    def mcr_db
      @optdb.update(
        i: 'interactive mode',
        n: 'non-stop mode'
      )
      self
    end

    # Current Options
    def current_options(str, ext_keys)
      (str.split('').map(&:to_sym) & (@optdb.keys + ext_keys))
    end

    # Make usage text
    def make_usage(optary)
      @index = {}
      optary.each do|c|
        @index["-#{c}"] = @optdb[c]
      end
      self
    end

    # Set @layer (default 'Wat')
    def make_layer
      lopt = %i(m x a f w).find { |c| self[c] } || :a
      @layer = @optdb[lopt].split(' ').first
      self
    end
  end
end
