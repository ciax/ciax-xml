#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libintfrms"
require "libmodapp"

class IntApps < Hash
  def initialize(par=[])
    super(){|h,k| h[k]=int(k,par)}
  end

  def add(id,par=[])
    self[id]=int(id,par)
  end

  private
  def int(id,par=[])
    adb=InsDb.new(id).cover_app
    case par
    when Array
      fint=IntFrms.new.add(id,par)[id]
      require "libappsv"
      aint=AppSv.new(adb,fint)
    else
      require "libappcl"
      aint=AppCl.new(adb,par)
    end
    aint.extend(ModApp).init(adb)
    aint
  end
end
