#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"

class Sym
  def initialize(doc)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @doc=doc
    @com=XmlDoc.new('sdb','all')
    @v=Verbose.new("Symbol")
    @sdb={}
    init_sym(doc)
    init_sym(@com)
    @ss={}
    init_ss(doc)
  end

  def convert(stat)
    conv={}
    stat.each{|k,v|
      case v
      when Hash
        val=v['val']
        h=v
      else
        val=v
        h={'val'=>v}
      end
      if sid=@ss[k]
        tbl=@sdb[sid][:table]
        case @sdb[sid]['type']
        when 'range'
          tbl.each{|match,hash|
            next unless ReRange.new(match) == val
            h.update(hash)
            @v.msg{"STAT:Range:[#{match}] and [#{val}]"}
          }
        when 'regexp'
          tbl.each{|match,hash|
            @v.msg{"STAT:Regexp:[#{match}] and [#{val}]"}
            next unless /#{match}/ === val
            h.update(hash)
          }
        else
          h.update(@sdb[sid][:table][val])
        end
      end
      conv[k]=h
    }
    conv
  end

  private
  def init_ss(doc)
    doc.find_each('status','value[@symbol]'){|e0|
      @ss[e0['id']]=e0['symbol']
    }
    @v.msg{"Stat-Symbol:#{@ss}"}
  end

  def init_sym(doc)
    doc.find_each('symbol','table'){|e1|
      row=e1.to_h
      id=row.delete('id')
      tbl=row[:table]={}
      e1.each{|e2|
        if e2.text
          tbl[e2.text]=e2.to_h
        else
          tbl.default=e2.to_h
        end
      }
      @sdb[id]=row
    }
    @v.msg{"Table:#{@sdb}"}
  end

end
