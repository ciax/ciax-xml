#!/usr/bin/ruby
require "libmsg"
require "libinsdb"

class IntFrms < Hash
  # opt 'f' is client, 's' is server, 'd' is dummy(from log)
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
    if opt['f']
      require "libfrmcl"
      return FrmCl.new(fdb,host)
    elsif opt['d']
      par=['frmsim',id]
    else
      par=[]
    end
    require "libfrmsv"
    fint=FrmSv.new(fdb,par)
    fint.server('frm')
    fint
  end
end
