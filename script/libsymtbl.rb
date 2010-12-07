#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"

class SymTbl
  def initialize(v=Verbose.new("Symbol"))
    @sdb=XmlDoc.new('sdb','all')
    @v=v
  end

  def get_symbol(id,val)
    set={'hl'=>'normal','val'=>val}
    return set unless id
    return set unless e=@sdb.select_id('symbol',id)
    set['type']=e['type']||'ENUM'
    e.each{|cs|
      @v.msg{"STAT:Symbol:compare [#{cs['val']}] and [#{val}]"}
      case e.name
      when 'enum'
        next unless cs['val'] == val
      when 'regexp'
        next unless /#{cs['val']}/ === val
      when 'range'
        next unless ReRange.new(cs['val']) == val
      end
      set['msg']=cs.text
      set.update(cs.attr)
      @v.msg{"STAT:Range:[#{set['msg']}] for [#{val}]"}
      break true
    } || set.update({'msg'=>'N/A','hl'=>'warn'})
    set
  end
end
