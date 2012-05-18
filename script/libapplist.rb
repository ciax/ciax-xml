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
  class List < Hash
    def initialize
      $opt||={'a'=>true}
      super{|h,id|
        idb=Ins::Db.new(id)
        adb=idb.cover_app
        if $opt['t']
          require "libappsh"
          aint=Sh.new(adb).extend(Test)
        elsif $opt['c'] or $opt['a']
          require "libappcl"
          aint=Cl.new(adb,$opt['h'])
        else
          require "libappsv"
          aint=Sv.new(adb).server
        end
        aint.cmdlist.add_group('dev',"Change Device",idb.list)
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
