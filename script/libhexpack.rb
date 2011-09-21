#!/usr/bin/ruby
# Ascii Pack
class HexPack
  def initialize(id)
    file="/home/ciax/config/sdb_#{id}.txt"
    @res=["%",id,'_','0','0','_','']
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

  def issue(flg)
    @res[4]= flg ? '1' : '0'
    self
  end

  def upd(stat)
    @res[3]=stat['run']
    @res[6]=''
    @list.each{|key|
      if val=stat[key]
        @res[6] << val
      else
        warn "NO key(#{key}) in Status"
      end
    }
    self
  end

  def to_s
    @res.join('')
  end
end

if __FILE__ == $0
  require "json"
  abort("Usage: #{$0} [status file]") if STDIN.tty? && ARGV.size < 1
  view=JSON.load(gets(nil))
  id=view['id']
  puts HexPack.new(id).upd(view['stat'])
end
