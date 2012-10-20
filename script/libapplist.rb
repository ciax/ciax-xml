#!/usr/bin/ruby
require "libmsg"
require "libappsh"
require "libinssh"
require "libinsdb"
# 'c' is client
# 'f' is client of frm level(need -c)
# 'h' is specified host
# 's' is server
# 'l' is sim by log(frmsim)
# 't' is check cmd only
module App
  autoload :Sv,"libappsv"
  class List < Hash
    def initialize
      $opt||={}
      super(){|h,id|
        idb=Ins::Db.new(id)
        adb=idb.cover_loc[:app]
        if $opt['t']
          aint=Test.new(adb)
        elsif $opt['c'] or $opt['a']
          aint=Cl.new(adb,$opt['h'])
        else
          aint=Sv.new(adb).server
        end
        aint.set_switch('dev',"Change Device",idb.list)
        h[id]=aint.ext_ins
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
