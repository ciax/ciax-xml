#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"

class StatSym
  def initialize(v)
    @sdb=XmlDoc.new('sdb','all')
    @v=v
  end

  def get_symbol(id,val)
    set={}
    return set unless id
    return set unless e=@sdb['symbols'].selid(id)
    set['type']=e['type']
    e.each{|enum|
      @v.msg{"STAT:Symbol:compare [#{enum.text}] and [#{val}]"}
      next unless /#{enum.text}/ === val
      set.update(enum.to_h)
      break true
    } || set.update({'msg'=>'N/A','hl'=>'warn'})
    @v.msg{"STAT:Symbol:[#{set['msg']}] for [#{val}]"}
    set
  end

  def get_level(id,val)
    set={}
    return set unless id
    return set unless e=@sdb['levels'].selid(id)
    e.each{|range|
      next unless ReRange.new(range.text) == val
      set.update(range.to_h)
      break true
    } || set.update({'msg'=>'N/A','hl'=>'warn'})
    @v.msg{"STAT:Level:[#{set['msg']}] for [#{val}]"}
    set
  end


end
