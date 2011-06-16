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
    exe=(stat['exe'] == '0000') ? '0' : '1'
    isu=(exe+stat['cmp']+stat['run'] == '100') ? '1' : '0'
    res="%#{@id}_#{exe}#{isu}_"
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
