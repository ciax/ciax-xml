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
class AppList < Hash
  def initialize
    $opt||={'a'=>true}
    super{|h,id|
#      warn "NO Hash (#{id}) then created"
      adb=InsDb.new(id).cover_app
      if $opt['t']
        require "libappint"
        aint=App::Int.new(adb)
      elsif $opt['a']
        require "libappcl"
        aint=App::Cl.new(adb,$opt['h'])
      else
        require "libappsv"
        aint=App::Sv.new(adb)
        aint.socket
      end
      h[id]=aint.extend(ShPrt)
    }
  end

  def setdef(id)
    self[nil]=self[id] if key?(id)
    self
  end
end

if __FILE__ == $0
  id=ARGV.shift
  ary=AppList.new
  puts ary[id]
end
