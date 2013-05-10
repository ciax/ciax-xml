#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libhexview"
require "libappsh"

module Hex
  def self.new(ash)
    Msg.type?(ash,App::Exe)
    if ['e','s','f','h','c'].any?{|i| $opt[i]}
      hsh=Hex::Sv.new(ash,$opt['e'])
    else
      hsh=Hex::Exe.new(ash.adb)
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
      @extdom=@cobj.add_extdom(@adb)
      self
    end
  end

  class Sv < Exe
    def initialize(ash,logging=nil)
      super(ash.adb)
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

  class List < Sh::List
    attr_reader :al
    def initialize(id)
      @al=App::List.new(id)
      super(id,Loc::Db.new.set(id).list)
    end

    def newsh(id)
      ldb=Loc::Db.new.set(id)
      sh=Hex.new(@al[id])
      switch_id(sh,'dev',"Change Device",ldb.list)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Hex::List.new(ARGV.shift).shell
end
