#!/usr/bin/ruby
require 'libmsg'
module CIAX
  # Global options
  class GetOpts < Hash
    # str = valid option list (afch:)
    # db = addigional option db
    attr_reader :layer
    def initialize(str = '', db = {})
      require 'optparse'
      Msg.type?(str, String)
      optdb = {}
      # Layer
      optdb['w'] = 'wat layer'
      optdb['a'] = 'app layer(default)'
      optdb['f'] = 'frm layer'
      optdb['x'] = 'hex layer'
      # Client option
      optdb['c'] = 'client'
      optdb['l'] = 'local client'
      optdb['h'] = 'client for [host]'
      # Comm to devices
      optdb['t'] = 'test mode (default)'
      optdb['s'] = 'simulation mode'
      optdb['e'] = 'execution mode'
      # For appearance
      optdb['v'] = 'visual output (default)'
      optdb['r'] = 'raw data output'
      optdb['j'] = 'json data output'
      # For macro
      optdb['i'] = 'interactive mode'
      optdb['n'] = 'non-stop mode'
      optdb['m'] = 'movable mode'
      optdb.update(db)
      # Merge additional db
      db.keys.each do|k|
        str << k unless str.include?(k)
      end
      # Make usage text
      @index = {}
      (str.split('') & optdb.keys).each do|c|
        @index["-#{c}"] = optdb[c]
      end
      update(ARGV.getopts(str))
      # Set @layer (default 'Wat')
      lopt = %w(x a f w).find { |c| self[c] } || 'a'
      @layer = optdb[lopt].split(' ').first
      $opt = self
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
  end
end
