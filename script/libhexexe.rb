#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libapplist"
require "libhexview"

module Hex
  module Exe
    def init(adb)
      @adb=Msg.type?(adb,Db)
      init_ver('Hex',2)
      self['id']=@adb['site_id']
      @extdom=@cobj.add_extdom(@adb,:command)
      @output=View.new(self,Status::Var.new.ext_file(@adb['site_id']))
      self
    end
  end

  class Test < Interactive::Exe
    def initialize(adb)
      super()
      extend(Exe).init(adb)
    end
  end

  class Sv < Interactive::Server
    def initialize(adb,aint,logging=nil)
      super()
      extend(Exe).init(adb)
      @output=View.new(self,aint.stat)
      @log_proc=UpdProc.new
      @extdom.reset_proc{|item|
        aint.exe(item.cmd)
        @log_proc.upd
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
    def filter_in(line)
      return [] if /^(strobe|stat)/ === line
      line.split(' ')
    end

    def filter_out
      @output.to_s
    end
  end

  class List < Interactive::List
    def initialize(opt=nil)
      @al=App::List.new(opt)
      @aint={}
      super{|id|
        ldb=Loc::Db.new(id)
        if @opt['e'] or @opt['s'] or @opt['f'] or @opt['h'] or @opt['c']
          @aint[id]=@al[ldb[:app]['site_id']]
          hint=Sv.new(ldb[:app],@aint[id],@opt['e'])
        else
          hint=Test.new(ldb[:app])
        end
        hint
      }
    end

    def shell(id)
      @init_proc=proc{|int|
        int.ext_shell
      }
      super
    end
  end
end
