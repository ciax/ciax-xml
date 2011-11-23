#!/usr/bin/ruby
require "optparse"
require "libinsdb"

class FrmInts < Hash
  def initialize(par=[])
    super{|h,k| add(k,par)}
  end

  def add(id,par=[])
    fdb=InsDb.new(id).cover_app.cover_frm
    case par
    when Array
      require "libfrmsv"
      self[id]=FrmSv.new(fdb,par)
    else
      require "libfrmcl"
      self[id]=FrmCl.new(fdb,par)
    end
    self
  end
end
