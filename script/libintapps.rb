#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libmodprt"

#opt 'c' is client, 's' is server
class IntApps < Hash
  def initialize
    super(){|h,k| h[k]=add(k,{},["frmsim",k])}
  end

  def default(id)
    self[nil]=self[id]
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
    self[id]=aint.extend(ModPrt).init(adb)
  end
end
