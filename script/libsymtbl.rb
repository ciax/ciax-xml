#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"

class SymTbl
  def initialize(v)
    @sdb=XmlDoc.new('sdb','all')
    @v=v
  end

  def get_symbol(id,val)
    set={}
    return set unless id
    return set unless e=@sdb.select_id('symbol',id)
    set['type']=e['type']||'ENUM'
    e.each{|cs|
      @v.msg{"STAT:Symbol:compare [#{cs.text}] and [#{val}]"}
      case e.name
      when 'enum'
        next unless /#{cs.text}/ === val
      when 'range'
        next unless ReRange.new(cs.text) == val
      end
      set.update(cs.attr)
      break true
    } || set.update({'msg'=>'N/A','hl'=>'warn'})
    @v.msg{"STAT:Range:[#{set['msg']}] for [#{val}]"}
    set
  end
end
