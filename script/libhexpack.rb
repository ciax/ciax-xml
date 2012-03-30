#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
class HexPack
  def initialize(view,prompt='')
    @val=Msg.type?(view,Rview)['stat']
    @v=Msg::Ver.new(self,6)
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
          @list << ary
        end
      end
    }
  end

  def to_s
    @res[3]=b2i(['isu','exe','run','jak'].any?{|r| @val[r].to_i > 0})
    @res[4]=b2i(@prompt.include?('*'))
    @res[6]=''
    @list.each{|key,title,len,type|
      if val=@val[key]
        case type
        when /FLOAT/
          str=("%0#{len}.2f" % val.to_f)
        when /INT/
          str=("%0#{len}d" % val.to_i)
        when /BINARY/
          str=("%0#{len}b" % val.to_i)
         else
          str=("%#{len}s" % val)
         end
        @v.msg{"#{title}/#{type}(#{len}) = #{str}"}
      else
        str='*' * len.to_i
      end
      @res[6] << str
    }
    @res.join('')
  end

  private
  def b2i(b) #Boolean to Integer (1,0)
    b ? '1' : '0'
  end
end

if __FILE__ == $0
  require "librview"
  Msg.usage("[view_file]") if STDIN.tty? && ARGV.size < 1
  view=Rview.new.load
  puts HexPack.new(view)
end
