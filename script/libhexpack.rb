#!/usr/bin/ruby
# Ascii Pack
require "libmsg"

# included in AppObj
module HexPack
  def init
    id=@stat['id'] || raise("NO ID in Stat")
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
    self
  end

  def to_s
    @res[3]=b2i(['isu','exe','run','jak'].any?{|r| @stat['val'][r].to_i > 0})
    @res[4]=b2i(@prompt.include?('*'))
    @res[6]=''
    @list.each{|key,title,len,type|
      if val=@stat['val'][key]
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
  require "libstat"
  class TestHex
    include HexPack
    def initialize
      @v=Msg::Ver.new(self,6)
      @stat=Stat.new.load
      @prompt=''
      init
    end
  end
  Msg.usage("[stat_file]") if STDIN.tty? && ARGV.size < 1
  int=TestHex.new
  puts int
end
