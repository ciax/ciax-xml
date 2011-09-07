#!/usr/bin/ruby
# Ascii Pack
class HexPack
  def initialize(id)
    file="/home/ciax/config/sdb_#{id}.txt"
    @id=id
    @isu='0'
    @list=[]
    @res=''
    open(file){|f|
      while line=f.gets
        key=line.split(',').first
        case key
        when /^[%#]/,/^$/
        else
          @list << key
        end
      end
    }
  end

  def issue
    @isu='1'
    self
  end

  def upd(stat)
    @res="%#{@id}_#{stat['run']}#{@isu}_"
    @list.each{|key|
      if val=stat[key]
        @res << val
      else
        warn "NO key(#{key}) in Status"
      end
    }
    self
  end

  def to_s
    @res
  end
end
