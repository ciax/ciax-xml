#!/usr/bin/ruby
require "libmsg"
require "libappsh"
require "liblocdb"
# 'f' is client of frm level(need -c)
# 'h' is specified host
# 'l' is sim by log(frmsim)
# 't' is check cmd only
module App
  autoload :Sv,"libappsv"
  class Slist < Hash
    def initialize
      $opt||={}
      super(){|h,id|
        ldb=Loc::Db.new(id)
        adb=ldb.cover_app[:app]
        if $opt['t']
          aint=Test.new(adb)
        else
          fdb=ldb.cover_frm[:frm]
          if $opt['f']
            aint=Sv.new(adb,fdb)
          else
            aint=Sv.new(adb,fdb,'localhost')
          end
          aint.fcl.set_switch('lay',"Change Layer",{'app'=>"App mode"})
          aint.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
          aint.set_switch('dev',"Change Device",ldb.list)
        end
        yield aint,id if defined? yield
        h[id]=aint
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
