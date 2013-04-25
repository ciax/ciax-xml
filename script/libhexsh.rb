#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libinslist"
require "libhexview"

module Hex
  def self.new(adb,ash)
    Msg.type?(adb,App::Db)
    Msg.type?(ash,App::Exe)
    if ['e','s','f','h','c'].any?{|i| $opt[i]}
       hsh=Hex::Sv.new(adb,ash,$opt['e'])
    else
      hsh=Hex::Exe.new(adb)
    end
    hsh
  end

  class Exe < Sh::Exe
    def initialize(adb)
      @adb=Msg.type?(adb,Db)
      init_ver('Hex',2)
      self['layer']='hex'
      self['id']=@adb['site_id']
      stat=Status::Var.new.ext_file(@adb['site_id'])
      prom=Sh::Prompt.new(self)
      super(View.new(self,stat),prom)
      @extdom=@cobj.add_extdom(@adb,:command)
      self
    end
  end

  class Sv < Exe
    def initialize(adb,ash,logging=nil)
      super(adb)
      @output=View.new(ash,ash.stat)
      @log_proc=UpdProc.new
      @extdom.reset_proc{|item|
        ash.exe(item.cmd)
        @log_proc.upd
      }
      @upd_proc.add{
        ash.stat.load
      }
      if logging
        logging=Logging.new('hex',self['id'],@adb['version']){
          {'hex' => @output.to_s}
        }
        @log_proc.add{logging.append}
      end
      ext_server(@adb['port'].to_i+1000)
    end

    private
    def server_input(line)
      return [] if /^(strobe|stat)/ === line
      line.split(' ')
    end

    def server_output
      @output.to_s
    end
  end
end
