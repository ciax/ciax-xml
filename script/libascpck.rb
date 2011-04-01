#!/usr/bin/ruby

class AscPck
  def initialize(id)
    file="/home/ciax/config/sdb_#{id}.txt"
    @id=id
    @list=[]
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

  def convert(stat)
    res="%#{@id}_#{stat['exe']}#{stat['isu']}_"
    @list.each{|key|
      if val=stat[key]
        res << val
      else
        warn "NO key(#{key}) in Status"
      end
    }
    res
  end
end
