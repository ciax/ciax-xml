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
    @sdb['symbols'].each_element_with_attribute('id',id){ |e|
        set['type']=e.attributes['type']
      e.each_element {|enum|
        @v.msg{"STAT:Symbol:compare [#{enum.text}] and [#{val}]"}
        next unless /#{enum.text}/ === val
        enum.attributes.each{|k,v| set[k]=v }
        break true
      } || set.update({'msg'=>'N/A','hl'=>'warn'})
      @v.msg{"STAT:Symbol:[#{set['msg']}] for [#{val}]"}
    }
    set
  end

  def get_level(id,val)
    set={}
    return set unless id
    @sdb['levels'].each_element_with_attribute('id',id){ |e|
      e.each_element {|range|
        next unless ReRange.new(range.text) == val
        range.attributes.each{|k,v| set[k]=v }
        break true
      } || set.update({'msg'=>'N/A','hl'=>'warn'})
      @v.msg{"STAT:Level:[#{set['msg']}] for [#{val}]"}
    }
    set
  end


end
