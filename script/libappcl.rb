#!/usr/bin/ruby
require "libmsg"
require "liblocdb"
require "libappsh"
require "libinssh"
# 'h' is specified host
# 'l' is sim by log(frmsim)
# 't' is check cmd only
module App
  class Clist < Hash
    def initialize(fhost=nil)
      $opt||={}
      super(){|h,id|
        ldb=Loc::Db.new(id)
        adb=ldb.cover_app[:app]
        fdb=ldb.cover_frm[:frm]
        aint=Cl.new(adb,fdb,$opt['h'])
        aint.fcl.set_switch('lay',"Change Layer",{'app'=>"App mode"})
        aint.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
        aint.set_switch('dev',"Change Device",ldb.list)
        h[id]=aint.ext_ins(id)
      }
    end
  end
end

if __FILE__ == $0
  id=ARGV.shift
  begin
    ary=App::Slist.new
    puts ary[id]
  rescue
    Msg.exit
  end
end
