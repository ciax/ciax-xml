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
    set={}
    return set unless id
    return set unless e=@sdb.select_id('symbol',id)
    set['type']=e['type']||'ENUM'
    begin
      case e.name
      when 'enum'
        sel=e.select('val',val)
        set['msg']=sel.text
        set.update(sel.attr)
      when 'range'
        e.each{|cs|
          @v.msg{"STAT:Symbol:compare [#{cs['val']}] and [#{val}]"}
          next unless ReRange.new(cs['val']) == val
          set['msg']=cs.text
          set.update(cs.attr)
          @v.msg{"STAT:Range:[#{set['msg']}] for [#{val}]"}
          break true
        } || raise(SelectID)
      end
    rescue SelectID
      set.update({'msg'=>'N/A','hl'=>'warn'})
    end
    set
  end
end
