#!/usr/bin/ruby
# Ascii Pack
require "libmsg"

# included in App::Sh
module HexPack
  class View
    extend Msg::Ver
    def initialize(int,stat)
      # Server Status
      @int=Msg.type?(int,Hash)
      @stat=Msg.type?(stat,Status::Var)
      id=stat.id || raise(InvalidID,"NO ID in Stat")
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
      @res[3]=b2i(['isu','exe','run','jak'].any?{|r| @stat.get(r).to_i > 0})
      @res[4]=b2i(@int['isu'])
      @res[6]=''
      @list.each{|key,title,len,type|
        len=len.to_i
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
          View.msg{"#{title}/#{type}(#{len}) = #{str}"}
        else
          str='*' * len
        end
        # str can exceed specified length
        @res[6] << str[0,len]
      }
      @res.join('')
    end

    private
    def b2i(b) #Boolean to Integer (1,0)
      b ? '1' : '0'
    end
  end

  module Sv
    def self.extended(obj)
      Msg.type?(obj,App::Sv)
      self
    end

    def server(id=nil,ver=nil)
      @hex=View.new(self,@stat)
      extend(Object::Logging).init('hexpack',id,ver) if id
      @buf.post_flush << proc{append([],to_s)}
      super(@port+1000){to_s}
    end

    def to_s
      super
      @hex.to_s
    end
  end
end

class App::Sv
  def ext_hex(id=nil,ver=nil)
    extend(HexPack::Sv).server(id,ver)
  end
end

if __FILE__ == $0
  require "libstatus"
  Msg.usage("[stat_file]") if STDIN.tty? && ARGV.size < 1
  stat=Status::Var.new.load
  int=HexPack::View.new({},stat)
  puts int
end
