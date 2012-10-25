#!/usr/bin/ruby
require "libmsg"
require "libappsh"
require "liblocdb"
require "libinssh"
# 'c' is client
# 'f' is client of frm level(need -c)
# 'h' is specified host
# 's' is server
# 'l' is sim by log(frmsim)
# 't' is check cmd only
module App
  autoload :Sv,"libappsv"
  class List < Hash
    def initialize(fhost=nil)
      $opt||={}
      super(){|h,id|
        ldb=Loc::Db.new(id)
        adb=ldb.cover_app[:app]
        if $opt['t']
          aint=Test.new(adb)
        else
          fdb=ldb.cover_frm[:frm]
          if $opt['c'] or $opt['a']
            aint=Cl.new(adb,fdb,$opt['h'])
          elsif $opt['f']
            aint=Sv.new(adb,fdb)
          else
            aint=Sv.new(adb,fdb,'localhost')
          end
          aint.fcl.set_switch('lay',"Change Layer",{'app'=>"App mode"})
          aint.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
          aint.set_switch('dev',"Change Device",ldb.list)
        end
        h[id]=aint.ext_ins(id)
      }
    end
  end
end

if __FILE__ == $0
  id=ARGV.shift
  begin
    ary=App::List.new
    puts ary[id]
  rescue
    Msg.exit
  end
end
