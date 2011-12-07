#!/usr/bin/ruby
require "libmsg"
require "libinsdb"
require "libshprt"

#opt 'c' is client, 's' is server
# 'd' is dummy (frmsim), 't' is check cmd only
class IntApps < Hash
  def initialize
    super(){|h,k| int(k,{'c'=>true}) }
  end

  def setdef(id)
    self[nil]=self[id] if key?(id)
    self
  end

  def add(id,opt={'t'=>true},host=nil)
    Msg.type?(opt,Hash)
    self[id]=int(id,opt,host)
    self
  end

  private
  def int(id,opt,host)
    adb=InsDb.new(id).cover_app
    if opt['t']
      require "libapp"
      aint=App.new(adb)
    elsif opt['c']
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
  end
end

if __FILE__ == $0
  id=ARGV.shift
  ary=IntApps.new
  puts ary[id]
end
