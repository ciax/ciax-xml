#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"
require "librepeat"

class Sym
  def initialize(doc)
    @doc=doc
    @com=XmlDoc.new('sdb','all')
    @rep=Repeat.new
    @v=Verbose.new("Symbol")
  end

  def convert(stat)
    conv={}
    ['id','class','frame','time'].each{|key|
      if stat[key]
        conv[key]=stat[key]
        stat.delete(key)
      end
    }
    if @doc
      @rep.each(@doc['symbol']){|e|
        id=@rep.subst(e['id'])
        if ref=e['ref']
          begin
            e=@doc.select_id('symbol',ref)
          rescue SelectID
            e=@com.select_id('symbol',ref)
          end
        end
        conv[id]=get_symbol(e,stat[id])
        }
    else
      stat.each{|key,val|
        conv[key]=get_symbol([],val)
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
