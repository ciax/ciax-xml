#!/usr/bin/ruby
require "optparse"
require "libinsdb"

class IntFrms < Hash
  def initialize(opt={},par=[]) # opt 'f' is client
    super(){|h,k| h[k]=int(k,opt,par)}
  end

  def add(id,opt={},par=[])
    self[id]=int(id,opt,par)
    self
  end

  private
  def int(id,opt={},par=[])
    fdb=InsDb.new(id).cover_app.cover_frm
    if opt['f']
      require "libfrmcl"
      fint=FrmCl.new(fdb,par.first)
    else
      require "libfrmsv"
      fint=FrmSv.new(fdb,par)
    end
    fint
  end
end
