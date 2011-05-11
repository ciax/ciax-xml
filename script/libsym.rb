#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "librerange"
require "libmodsym"

class Sym
  include ModSym
  def initialize(db)
    @v=Verbose.new("Symbol",4)
    @doc=XmlDoc.new('sdb','all')
    @table=init_sym(db.table)
    @symbol=db.symbol
    @v.msg{"Stat-Symbol:#{@symbol}"}
  end

  def convert(stat)
    result={}
    stat.each{|k,v|
      result[k]=v
      val=v['val']
      next if val == ''
      next unless sid=@symbol[k]
      @v.msg{"ID=#{k},symbol=#{sid}"}
      tbl=@table[sid][:record]
      case @table[sid]['type']
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
        @v.msg{"STAT:Match:[#{match}] and [#{val}]"}
        v.update(@table[sid][:record][val])
      end
    }
    result
  end
end
