#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintfrms"
require "libmodapp"

class IntApps < Hash
  def initialize(opt={},par=[]) #opt is client level, 'a'=app, 'f'=frm
    super(){|h,k| h[k]=int(k,opt,par)}
  end

  def add(id,opt={},par=[])
    self[id]=int(id,opt,par)
    self
  end

  private
  def int(id,opt,par=[])
    adb=InsDb.new(id).cover_app
    if opt['a']
      require "libappcl"
      aint=AppCl.new(adb,par.first)
    else
      par=par.first if opt['f']
      fint=IntFrms.new.add(id,par)[id]
      require "libappsv"
      aint=AppSv.new(adb,fint)
    end
    aint.extend(ModApp).init(adb)
    aint
  end
end
