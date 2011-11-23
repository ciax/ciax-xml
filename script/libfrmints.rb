#!/usr/bin/ruby
require "optparse"
require "libinsdb"

class FrmInts < Hash
  def initialize(par=[])
    super(){|h,k| h[k]=int(k,par)}
  end

  def add(id,par=[])
    self[id]=int(id,par)
    self
  end

  private
  def int(id,par=[])
    fdb=InsDb.new(id).cover_app.cover_frm
    case par
    when Array
      require "libfrmsv"
      fint=FrmSv.new(fdb,par)
    else
      require "libfrmcl"
      fint=FrmCl.new(fdb,par)
    end
    fint
  end
end
