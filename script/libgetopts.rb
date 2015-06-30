#!/usr/bin/ruby
require "libmsg"
module CIAX
  # Global options
  class GetOpts < Hash
    # str = valid option list (afch:)
    # db = addigional option db
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
      # Merge additional db
      db.keys.each{|k|
        str << k unless str.include?(k)
      }
      # Make usage text 
      @index={}
      (str.split('') & optdb.keys).each{|c|
        @index["-#{c}"]=optdb[c]
      }
      update(ARGV.getopts(str))
      # -h: takes hostname (default 'localhost')
      self['h']= 'localhost' if self['h'] && /^\W/ =~ self['h']
      # Set @layer (default 'Wat')
      @layer=['Hex','App','Frm','Wat'].find{|c| self[c[0].downcase]}||'Wat'
      $opt=self
    end

    def layer
      eval @layer
    end

    def usage(str)
      Msg.usage(str+"\n"+Msg.columns(@index))
    end
  end
end
