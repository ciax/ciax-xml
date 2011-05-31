#!/usr/bin/ruby
require "libverbose"
require "librerange"

class Sym
  def initialize(table,ref)
    @v=Verbose.new("Symbol",6)
    @table=table
    @ref=ref||{}
  end

  def convert(view)
    list=[]
    view['list'].each{|v|
      k=v['id']
      list << v
      val=v['val']
      next if val == ''
      next unless sid=@ref[k]
      @v.msg{"ID=#{k},ref=#{sid}"}
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
        @v.msg{"VIEW:No Symbol Reference:[#{val}]"}
        v.update(@table[sid][:record][val])
      end
    }
    view['list']=list
    self
  end
end
