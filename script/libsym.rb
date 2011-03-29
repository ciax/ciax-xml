#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"
require "librepeat"

class Sym
  def initialize(doc)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
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
    tbl={}
    if @doc['symbol']
      @rep.each(@doc['symbol']){|e|
        id=@rep.subst(e['id'])
        if ref=e['ref']
          begin
            e=@doc.select_id('symbol',ref)
          rescue SelectID
            e=@com.select_id('symbol',ref)
          end
        end
        tbl[id]=get_symbol(e,stat[id])
      }
    end
    stat.each{|id,val|
      conv[id]=tbl[id] ? tbl[id] : get_symbol([],val)
    }
    conv
  end

  def get_symbol(e,val)
    case val
    when Hash
      set=val
    else
      set={'val'=>val,'msg'=>e['msg']}
      set['class'] = e['class'] || 'normal'
    end
    e.each{|cs|
      @v.msg{"STAT:Symbol:compare [#{cs.text}] and [#{val}]"}
      case cs.name
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
