#!/usr/bin/ruby
require "libsymdb"
require "libverbose"
require "librerange"

class Sym
  def initialize
    @v=Verbose.new("Symbol",4)
    @table=SymDb.new
    @symbol={}
  end

  def update(db)
    @table.update(db.table)
    @symbol.update(db.symbol)
    @v.msg{"Stat-Symbol:#{@symbol}"}
  end

  def convert(view)
    list=[]
    view['list'].each{|v|
      k=v['id']
      list << v
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
          @v.msg{"VIEW:Range:[#{match}] and [#{val}]"}
        }
      when 'regexp'
        tbl.each{|match,hash|
          @v.msg{"VIEW:Regexp:[#{match}] and [#{val}]"}
          next unless /#{match}/ === val
          v.update(hash)
        }
      else
        @v.msg{"VIEW:Match:[#{match}] and [#{val}]"}
        v.update(@table[sid][:record][val])
      end
    }
    view['list']=list
    view
  end
end
