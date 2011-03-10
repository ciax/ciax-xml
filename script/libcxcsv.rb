#!/usr/bin/ruby

class CxCsv
  def initialize(id)
    file="/home/ciax/config/sdb_#{id}.txt"
    @id=id
    @list=[]
    open(file){|f|
      while line=f.gets
        next unless /.+/ === line
        @list << line.split(',').first
    end
    }
  end

  def mkres(stat)
    res="%#{@id}_#{stat['exe']}#{stat['isu']}_"
    @list.each{|key|
      res << stat[key]
    }
    res
  end
end
