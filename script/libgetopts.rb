#!/usr/bin/ruby
require "libmsg"
module CIAX
  # Global options
  class GetOpts < Hash
    attr_reader :layer
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
      optdb['l']='local client'
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
      optdb['i']='interactive mode'
      optdb['n']='non-stop mode'
      optdb['m']='movable mode'
      optdb.update(db)
      db.keys.each{|k|
        str << k unless str.include?(k)
      }
      @index={}
      (str.split('') & optdb.keys).each{|c|
        @index["-#{c}"]=optdb[c]
      }
      update(ARGV.getopts(str))
      self['h']= 'localhost' if self['h'] && /^\W/ =~ self['h']
      ['Wat','App','Frm','Hex'].each{|c|
        eval "@layer=#{c}" if self[c[0].downcase]
      }
      $opt=self
    end

    def usage(str)
      Msg.usage(str+"\n"+Msg.columns(@index))
    end
  end
end
