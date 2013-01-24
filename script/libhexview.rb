#!/usr/bin/ruby
# Ascii Pack
require "libmsg"

module Hex
  class View
    include Msg::Ver
    def initialize(int,stat)
      # Server Status
      init_ver('HexView',4)
      @int=Msg.type?(int,Hash)
      @stat=Msg.type?(stat,Status::Var)
      id=stat['id'] || raise(InvalidID,"NO ID in Stat")
      file=View.sdb(id) || raise(InvalidID,"Hex/Can't found SDB for #{id}")
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

    def self.sdb(id)
      file="/home/ciax/config/sdb_#{id}.txt"
      test(?r,file) && file
    end

    def to_s
      @stat.load
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
          verbose{"#{title}/#{type}(#{len}) = #{str}"}
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
end

if __FILE__ == $0
  require "libstatus"
  Msg.usage("[stat_file]") if STDIN.tty? && ARGV.size < 1
  stat=Status::Var.new
  int=Hex::View.new({},stat)
  puts int
end
