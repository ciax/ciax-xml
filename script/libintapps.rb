#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libmodapp"

class IntApps < Hash
  def initialize(opt={},par=[]) #opt 'c' is client, 'd' is for frm
    super(){|h,k| h[k]=int(k,opt,par)}
  end

  def add(id,opt={},par=[])
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
    aint.extend(ModApp).init(adb)
    aint
  end
end
