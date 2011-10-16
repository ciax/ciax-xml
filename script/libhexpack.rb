#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
class HexPack
  def initialize(view,prompt='')
    @stat=Msg.type?(view,Rview)['stat']
    id=view['id']||raise
    @prompt=prompt
    file="/home/ciax/config/sdb_#{id}.txt"
    @res=["%",id,'_','0','0','_','']
    @list=[]
    open(file){|f|
      while line=f.gets
        ary=line.split(',')
        case line
        when /^[%#]/,/^$/
        else
          @list << [ary[0],ary[2]]
        end
      end
    }
  end

  def upd
    @res[3]=@stat['run']
    @res[4]= @prompt.include?('*') ? '1' : '0'
    @res[6]=''
    @list.each{|key,len|
      if val=@stat[key]
        @res[6] << (len=='1' ? val : ("%0#{len}b" % val.to_i))
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
  require "librview"
  abort("Usage: #{$0} [view_file]") if STDIN.tty? && ARGV.size < 1
  view=Rview.new.upd
  puts HexPack.new(view).upd
end
