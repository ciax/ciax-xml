#!/usr/bin/ruby
require "libmsg"
require "libinsdb"
require "libshprt"

#opt 'c' is client, 's' is server, 'd' is dummy (frmsim)
class IntApps < Hash
  def initialize(host=nil)
    super(){|h,k| add(k,{'c'=>true},host) }
  end

  def setdef(id)
    self[nil]=self[id] if key?(id)
    self
  end

  def add(id,opt={'c'=>true},host='localhost')
    Msg.type?(opt,Hash)
    adb=InsDb.new(id).cover_app
    if opt['c']
      require "libappcl"
      aint=AppCl.new(adb,host)
    else
      require "libintfrms"
      require "libappsv"
      require 'libserver'
      fint=IntFrms.new.add(id,opt,host)[id]
      aint=AppSv.new(adb,fint)
      Server.new(aint.port,aint.prompt){|line|
        aint.exe(line)
      } if opt['s']
    end
    aint.extend(ShPrt).init(adb)
    self[id]=aint
  end
end

if __FILE__ == $0
  id=ARGV.shift
  ary=IntApps.new
  puts ary[id]
end
