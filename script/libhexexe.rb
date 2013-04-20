#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libapplist"
require "libhexview"

module Hex
  class Exe < Interactive::Exe
    def initialize(adb)
      @adb=Msg.type?(adb,Db)
      init_ver('Hex',2)
      self['id']=@adb['site_id']
      stat=Status::Var.new.ext_file(@adb['site_id'])
      super(View.new(self,stat))
      @extdom=@cobj.add_extdom(@adb,:command)
      self
    end
  end

  class Test < Exe;end

  class Sv < Exe
    def initialize(adb,aint,logging=nil)
      super(adb)
      @output=View.new(aint,aint.stat)
      @log_proc=UpdProc.new
      @extdom.reset_proc{|item|
        aint.exe(item.cmd)
        @log_proc.upd
      }
      @upd_proc.add{
        aint.stat.load
      }
      if logging
        logging=Logging.new('hex',self['id'],@adb['version']){
          {'hex' => @output.to_s}
        }
        @log_proc.add{logging.append}
      end
      server(@adb['port'].to_i+1000)
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

  class List < Interactive::List
    def initialize
      @al=App::List.new
      @aint={}
      super{|id|
        ldb=Loc::Db.new(id)
        if ['e','s','f','h','c'].any?{|i| $opt[i]}
          @aint[id]=@al[ldb[:app]['site_id']]
          hint=Sv.new(ldb[:app],@aint[id],$opt['e'])
        else
          hint=Test.new(ldb[:app])
        end
        hint
      }
    end
  end
end
