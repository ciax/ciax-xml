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
    fint=nil
    if opt['f']
      require "libfrmcl"
      fint=FrmCl.new(fdb,par.first)
    else
      require "libfrmsv"
      require 'libserver'
      fint=FrmSv.new(fdb,par)
      fint[:thread]=Thread.new{
        Server.new(fint.port,fint.prompt){|line|
          fint.exe(line)
        }
      }
    end
    fint
  end
end
