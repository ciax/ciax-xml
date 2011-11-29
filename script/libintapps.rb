#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libmodprt"

#opt 'c' is client, 's' is server
class IntApps < Hash
  def initialize
    super{|h,k| add(k,{},["frmsim",k]) }
  end

  def setdef(id)
    self[nil]=self[id] if key?(id)
    self
  end

  def add(id,opt={'c'=>true},par=['localhost'])
    adb=InsDb.new(id).cover_app
    if opt['c']
      require "libappcl"
      aint=AppCl.new(adb,par.first)
    else
      require "libintfrms"
      require "libappsv"
      require 'libserver'
      fint=IntFrms.new.add(id,opt,par)[id]
      aint=AppSv.new(adb,fint)
      Server.new(aint.port,aint.prompt){|line|
        aint.exe(line)
      } if opt['s']
    end
    aint.extend(ModPrt).init(adb)
    self[id]=aint
  end
end

if __FILE__ == $0
  id=ARGV.shift
  ary=IntApps.new
  puts ary[id]
end
