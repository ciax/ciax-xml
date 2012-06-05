#!/usr/bin/ruby
require "libmsg"
require "libinsdb"
require "libappprt"
# 'c' is client
# 'f' is client of frm level(need -c)
# 'h' is specified host
# 's' is server
# 'l' is sim by log(frmsim)
# 't' is check cmd only
module App
  autoload :Sh,"libappsh"
  autoload :Cl,"libappcl"
  autoload :Sv,"libappsv"
  class List < Hash
    def initialize(proj=nil)
      $opt||={}
      super(){|h,id|
        idb=Ins::Db.new(id,proj)
        adb=idb.cover_app
        if $opt['t']
          aint=Sh.new(adb).extend(Test)
        elsif $opt['c'] or $opt['a']
          aint=Cl.new(adb,$opt['h'])
        else
          aint=Sv.new(adb).server
        end
        aint.set_switch('dev',"Change Device",idb.list)
        h[id]=aint.extend(App::Prt)
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
