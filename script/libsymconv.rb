#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"

class SymConv
  def initialize(dbl,root,xpath,key)
    @dbl=dbl
    @sdl={}
    dbl[root].each(xpath){|e|
      sym=e['symbol'] || next
      @sdl[e[key]]=sym
    }
    @dba=XmlDoc.new('sdb','all')
    @v=Verbose.new("Symbol")
  end

  def get_symbol(id,val)
    set={'class'=>'normal'}
    begin
      e=select_id(@sdl[id])
    rescue SelectID
      return set.update({'val'=>val})
    end
    e.each{|cs|
      @v.msg{"STAT:Symbol:compare [#{cs.text}] and [#{val}]"}
      case e.name
      when 'enum'
        next unless cs.text == val
      when 'regexp'
        next unless /#{cs.text}/ === val
      when 'range'
        next unless ReRange.new(cs.text) == val
        set['val']=val
      end
      set['msg']=cs['msg']
      set['class']=cs['class']
      @v.msg{"STAT:Range:[#{set['msg']}] for [#{val}]"}
      break true
    } || set.update({'msg'=>'N/A','hl'=>'warn'})
    set
  end

  def select_id(id)
    return @dbl.select_id('symbol',id) rescue SelectID
    return @dba.select_id('symbol',id)
  end
end
