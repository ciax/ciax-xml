#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"
require "librepeat"

class View
  def initialize(dbl)
    @dbl=dbl
    @sdl={}
    rep=Repeat.new
    rep.each(dbl['view']){|e|
      sym=e['symbol'] || next
      @sdl[rep.subst(e['id'])]=sym
    }
    @dba=XmlDoc.new('sdb','all')
    @v=Verbose.new("Symbol")
  end

  def convert(stat)
    conv={}
    stat.each{|key,val|
      case key
      when 'id','time','class','frame'
        conv[key]=val
      else
        conv[key]=get_symbol(key,val)
      end
    }
    conv
  end

  def overwrite(stat)
    stat.each{|key,val|
      case val
      when Hash
        stat[key].update(get_symbol(key,val['val']))
      end
    }
    stat
  end

  def get_symbol(id,val)
    set={'class'=>'normal','val'=>val}
    begin
      e=select_id(@sdl[id])
    rescue SelectID
      return set
    end
    e.each{|cs|
      @v.msg{"STAT:Symbol:compare [#{cs.text}] and [#{val}]"}
      case e.name
      when 'enum'
        next unless cs.text == val
        set['msg']=cs['msg']
      when 'regexp'
        next unless /#{cs.text}/ === val
        set['msg']=cs['msg']
      when 'range'
        next unless ReRange.new(cs.text) == val
        set['level']=cs['msg']
      end
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
