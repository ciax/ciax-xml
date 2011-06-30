#!/usr/bin/ruby
# Ascii Pack
class AscPck
  def initialize(id,stat)
    file="/home/ciax/config/sdb_#{id}.txt"
    @id=id
    @stat=stat
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
    upd
  end

  def issue(s=self)
    @stat['isu']='1'
    s
  end

  def upd
    @res="%#{@id}_#{@stat['run']}#{@stat['isu']}_"
    @list.each{|key|
      if val=@stat[key]
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
