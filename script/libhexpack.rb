#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
class HexPack
  def initialize(view,prompt=[''])
    @stat=Msg.type?(view['stat'],Hash)
    id=view['id']||raise
    @prompt=Msg.type?(prompt,Array)
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

  def upd
    @res[3]=@stat['run']
    @res[4]= @prompt.first.include?('*') ? '1' : '0'
    @res[6]=''
    @list.each{|key|
      if val=@stat[key]
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
  puts HexPack.new(view).upd
end
