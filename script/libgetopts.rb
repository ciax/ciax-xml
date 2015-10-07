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
      optary = current_options(str) + db.keys
      make_usage(optary)
      update(ARGV.getopts(optary.join('')))
      make_layer
    end

    def sv?
      %w(s e).any? { |k| self[k] }
    end

    def cl?
      %w(h c l).any? { |k| self[k] }
    end

    def host
      self['h'] || 'localhost' unless self['c']
    end

    def usage(str)
      Msg.usage(str + "\n" + Msg.columns(@index))
    end

    private

    def make_db
      layer_db
      cli_db
      mode_db
      vis_db
      mcr_db
    end

    # Layer option
    def layer_db
      @optdb['w'] = 'wat layer'
      @optdb['a'] = 'app layer(default)'
      @optdb['f'] = 'frm layer'
      @optdb['x'] = 'hex layer'
      self
    end

    # Client option
    def cli_db
      @optdb['c'] = 'client'
      @optdb['l'] = 'local client'
      @optdb['h'] = 'client for [host]'
      self
    end

    # Comm to devices
    def mode_db
      @optdb['t'] = 'test mode (default)'
      @optdb['s'] = 'simulation mode'
      @optdb['e'] = 'execution mode'
      self
    end

    # For visual
    def vis_db
      @optdb['v'] = 'visual output (default)'
      @optdb['r'] = 'raw data output'
      @optdb['j'] = 'json data output'
      self
    end

    # For macro
    def mcr_db
      @optdb['i'] = 'interactive mode'
      @optdb['n'] = 'non-stop mode'
      @optdb['m'] = 'movable mode'
      self
    end

    # Current Options
    def current_options(str)
      (str.split('') & @optdb.keys)
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
      lopt = %w(x a f w).find { |c| self[c] } || 'a'
      @layer = @optdb[lopt].split(' ').first
      self
    end
  end
  OPT = GetOpts.new
end
