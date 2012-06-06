#!/usr/bin/ruby
# Ascii Pack
require "libmsg"

# included in App::Sh
module HexPack
  extend Msg::Ver
  def self.extended(obj)
    init_ver(obj)
    Msg.type?(obj,App::Sh).init
  end

  def init
    id=@stat.id || raise(InvalidID,"NO ID in Stat")
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

  def server
    @port+=1000
    super(false)
  end

  def to_s
    @res[3]=b2i(['isu','exe','run','jak'].any?{|r| @stat.get(r).to_i > 0})
    @res[4]=b2i(@prompt['isu'])
    @res[6]=''
    @list.each{|key,title,len,type|
      if val=@stat.get(key)
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
        HexPack.msg{"#{title}/#{type}(#{len}) = #{str}"}
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
  require "libstatus"
  class TestHex
    include HexPack
    def initialize
      @stat=Status::Var.new.load
      @prompt={}
      init
    end
  end
  Msg.usage("[stat_file]") if STDIN.tty? && ARGV.size < 1
  int=TestHex.new
  puts int
end
