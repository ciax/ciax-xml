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
      optdb['w']='wat layer (default)'
      optdb['a']='app layer'
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
      optdb['j']='json data output'
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
      $layer=[]
      {'f' => Frm, 'a' => App, 'w' => Wat, 'x' => Hex}.each{|k,v| $layer << v if self[k] }
      $opt=self
    end

    def usage(str)
      Msg.usage([str,*@list].join("\n"))
    end
  end
end
