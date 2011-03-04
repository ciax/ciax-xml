#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"
require "librepeat"

class Sym
  def initialize(tbl)
    @tbl=tbl
    @com=XmlDoc.new('sdb','all')
    @rep=Repeat.new
    @v=Verbose.new("Symbol")
  end

  def convert(stat)
    conv={}
    ['id','class','frame','time'].each{|key|
      conv[key]=stat[key] if stat[key]
    }
    if @tbl
      @rep.each(@tbl){|e|
        id=@rep.subst(e['id'])
        if ref=e['ref']
          e=@tbl.select_id('symbol',ref) rescue SelectID
          e=@com.select_id('symbol',ref)
        end
        conv[id]=get_symbol(e,stat[id])
      }
    end
    conv
  end

  def get_symbol(e,val)
    case val
    when Hash
      set=val
    else
      set={'class'=>'normal','val'=>val}
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
    }
    set
  end
end
