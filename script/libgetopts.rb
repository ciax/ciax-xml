#!/usr/bin/ruby
require "libmsg"
module CIAX
  # Global options
  class GetOpts < Hash
    def initialize(str='',db={})
      require 'optparse'
      Msg.type?(str,String)
      optdb={}
      #Layer
      optdb['a']='app layer (default)'
      optdb['f']='frm layer'
      optdb['x']='hex layer'
      #Client option
      optdb['c']='client'
      optdb['h']='client for [host]'
      #Comm to devices
      optdb['t']='test mode (default)'
      optdb['s']='simulation mode'
      optdb['e']='execution mode'
      #For appearance
      optdb['v']='visual output (default)'
      optdb['r']='raw data output'
      #For macro
      optdb['n']='non-stop mode'
      optdb['l']='local client'
      optdb['m']='movable mode'
      optdb.update(db)
      db.keys.each{|k|
        str << k unless str.include?(k)
      }
      @list=str.split('').map{|c|
        optdb.key?(c) && Msg.item("-"+c,optdb[c]) || nil
      }.compact
      update(ARGV.getopts(str))
      $opt=self
    end

    def usage(str)
      Msg.usage([str,*@list].join("\n"))
    end
  end
end
