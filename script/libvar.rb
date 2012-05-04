#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libupdate"

module Val
  def to_s
    Msg.view_struct(self,'val')
  end
end

class Var < ExHash
  attr_reader :type,:id,:ver,:val,:at_upd
  def initialize(type)
    super()
    self['type']=@type=type
    self.val=Hash.new
    set_time
    @at_upd=Update.new
  end

  def upd
    @at_upd.upd
    self
  end

  def get(key)
    @val[key]
  end

  # Update with str (key=val,key=val,..)
  def str_update(str)
    Msg.type?(str,String)
    str.split(',').each{|i|
      k,v=i.split('=')
      @val[k]=v
    }
    set_time
    self
  end

  def unset(key)
    @val.delete(key)
  end

  def id=(id)
    self['id']=@id=id
  end

  # Version Number
  def ver=(ver)
    self['ver']=@ver=ver
  end

  def val=(val)
    self['val']=@val=val.extend(Val)
  end

  def set_time(time=nil)
    @val['time']=time||Msg.now
    self
  end

  def load(json_str=nil)
    super
    bind_var
    self
  end

  private
  def bind_var
    ['type','id','ver','val'].each{|k|
      eval "@#{k}=self['#{k}']"
    }
  end
end
