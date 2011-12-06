#!/usr/bin/ruby
require "libmsg"
require "libinsdb"

class IntFrms < Hash
  # opt 'c' is client, 's' is server, 'd' is dummy(from log)
  def initialize(opt={},host=nil)
    Msg.type?(opt,Hash)
    super(){|h,k| h[k]=int(k,opt,host)}
  end

  def add(id,opt={},host='localhost')
    Msg.type?(opt,Hash)
    self[id]=int(id,opt,host)
    self
  end

  private
  def int(id,opt={},host=nil)
    Msg.type?(opt,Hash)
    fdb=InsDb.new(id).cover_app.cover_frm
    if opt['c']
      require "libfrmcl"
      return FrmCl.new(fdb,host)
    elsif opt['d']
      par=['frmsim',id]
    else
      par=[]
    end
    require "libfrmsv"
    require 'libserver'
    fint=FrmSv.new(fdb,par)
    Server.new(fint.port,fint.prompt){|line|
      fint.exe(line)
    } if opt['s']
    fint
  end
end
