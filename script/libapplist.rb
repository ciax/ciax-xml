#!/usr/bin/ruby
require "libmsg"
require "libinsdb"
require "libappprt"

# 'a' is client of app server
# 'f' is client of frm server
# 's' is server
# 'd' is dummy (frmsim)
# 't' is check cmd only
# 'h' is specified host
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
        elsif $opt['a']
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
