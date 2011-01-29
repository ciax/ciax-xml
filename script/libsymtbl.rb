#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"

class SymTbl
  def initialize(dba=[])
    @dba=dba
    dba.unshift(XmlDoc.new('sdb','all'))
    @v=Verbose.new("Symbol")
  end

  def get_symbol(id,val)
    set={'hl'=>'normal','val'=>val}
    return set unless id
    e=select_id(id)
    return set unless e
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
      set['class']=cs['class']
      @v.msg{"STAT:Range:[#{set['msg']}] for [#{val}]"}
      break true
    } || set.update({'msg'=>'N/A','hl'=>'warn'})
    set
  end

  def select_id(id)
    @dba.each{|db|
      begin
        return db.select_id('symbol',id) if db
      rescue SelectID
      end
    }
  end
end
