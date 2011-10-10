#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libsymstat"
# Status to Wview (String with attributes)
class Wview < Rview
  def initialize(id,adb,stat)
    super(id)
    @sym=SymStat.new(adb)
    self['stat']=Msg.type?(stat,AppStat)
  end

  def upd
    update(@sym.mksym(self['stat']))
  end

  def save
    open(@uri,'w'){|f| f << to_j }
    self
  end
end
