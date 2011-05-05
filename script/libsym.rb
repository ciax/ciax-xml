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
    @v=Verbose.new("Symbol",4)
    @rep=Repeat.new
    @sdb={}
    init_sym(doc)
    init_sym(@com)
    @ss={}
    init_frm(doc)
    init_cls(doc)
    @v.msg{"Stat-Symbol:#{@ss}"}
  end

  def convert(stat)
    result={}
    stat.each{|k,v|
      result[k]=v
      val=v['val']
      next if val == ''
      next unless sid=@ss[k]
      @v.msg{"ID=#{k},symbol=#{sid}"}
      tbl=@sdb[sid][:table]
      case @sdb[sid]['type']
      when 'range'
        tbl.each{|match,hash|
          next unless ReRange.new(match) == val
          v['val']=val.to_f
          v.update(hash)
          @v.msg{"STAT:Range:[#{match}] and [#{val}]"}
        }
      when 'regexp'
        tbl.each{|match,hash|
          @v.msg{"STAT:Regexp:[#{match}] and [#{val}]"}
          next unless /#{match}/ === val
          v.update(hash)
        }
      else
        v.update(@sdb[sid][:table][val])
      end
    }
    result
  end

  private
  def init_cls(doc)
    @rep.each(doc['status']){|e0|
      @ss[@rep.format(e0['id'])]=e0['symbol'] if e0['symbol']
    }
  end

  def init_frm(doc)
    doc.find_each('rspframe','*[@symbol]'){|e0|
      @ss[e0['assign']]=e0['symbol']
    }
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
