#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmints"
require "libmodapp"

class AppInts < Hash
  def initialize(par=[])
    super(){|h,k| add(k,par)}
  end

  def add(id,par=[])
    adb=InsDb.new(id).cover_app
    case par
    when Array
      fint=FrmInts.new.add(id,par)[id]
      require "libappsv"
      self[id]=AppSv.new(adb,fint)
    else
      require "libappcl"
      self[id]=AppCl.new(adb,par.first)
    end
    self[id].extend(ModApp).init(adb)
  end
end
