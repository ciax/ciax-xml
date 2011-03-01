#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"
require "librepeat"

class SymConv
  def initialize(dbl,domain,key,xpath=nil)
    @dbl=dbl
    @sdl={}
    if xpath
      dbl.find_each(domain,xpath){|e|
        sym=e['symbol'] || next
        @sdl[e[key]]=sym
      }
    else
      rep=Repeat.new
      rep.each(dbl[domain]){|e|
        sym=e['symbol'] || next
        @sdl[rep.subst(e[key])]=sym
      }
    end
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
