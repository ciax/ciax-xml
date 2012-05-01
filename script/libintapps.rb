#!/usr/bin/ruby
require "libmsg"
require "libinsdb"
require "libshprt"

# 'a' is client of app server
# 'f' is client of frm server
# 's' is server
# 'd' is dummy (frmsim)
# 't' is check cmd only
# 'h' is specified host
class IntApps < Hash
  def initialize
    $opt||={'a'=>true}
    super(){|h,id|
      adb=InsDb.new(id).cover_app
      if $opt['t']
        require "libappobj"
        aint=App::Int.new(adb)
      elsif $opt['a']
        require "libappcl"
        aint=App::Cl.new(adb,$opt['h'])
      else
        require "libintfrms"
        require "libappsv"
        fint=IntFrms.new[id]
        aint=App::Sv.new(adb,fint)
        aint.socket
      end
      aint.extend(ShPrt)
    }
  end

  def setdef(id)
    self[nil]=self[id] if key?(id)
    self
  end
end

if __FILE__ == $0
  id=ARGV.shift
  ary=IntApps.new
  puts ary[id]
end
