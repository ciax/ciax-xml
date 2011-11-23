#!/usr/bin/ruby
require "optparse"
require "libinsdb"

class IntFrms < Hash
  def initialize(opt={},par=[]) # opt 'c' is client, 's' is server
    super(){|h,k| h[k]=int(k,opt,par)}
  end

  def add(id,opt={},par=[])
    self[id]=int(id,opt,par)
    self
  end

  private
  def int(id,opt={},par=[])
    fdb=InsDb.new(id).cover_app.cover_frm
    if opt['c']
      require "libfrmcl"
      fint=FrmCl.new(fdb,par.first)
    else
      require "libfrmsv"
      require 'libserver'
      fint=FrmSv.new(fdb,par)
      Server.new(fint.port,fint.prompt){|line|
        fint.exe(line)
      } if opt['s']
    end
    fint
  end
end
