#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libmodprt"

#opt 'c' is client, 's' is server
class IntApps < Hash
  def initialize
    super(){|h,k| h[k]=int(k,{},["frmsim",k])}
  end

  def add(id,opt={'c'=>true},par=['localhost'])
    self[id]=int(id,opt,par)
    self
  end

  private
  def int(id,opt={},par=[])
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
    aint
  end
end
