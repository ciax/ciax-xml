#!/usr/bin/ruby
# Ascii Pack
require "libvarx"

module CIAX
  module Hex
    class View < Varx
      #hint should have server status (isu,watch,exe..) like App::Exe
      def initialize(id,ver,hint,stat)
        super('hex',id,ver)
        # Server Status
        @hint=type?(hint,Hash)
        @stat=type?(stat,App::Status)
        id=stat['id'] || id_err("NO ID(#{id}) in Stat")
        file=View.sdb(id) || id_err("Hex/Can't found sdb_#{id}.txt")
        @res=["%",id,'_','0','0','_','']
        @list=[]
        open(file){|f|
          while line=f.gets
            ary=line.split(',')
            case line
            when /^[#]/,/^$/
            else
              @list << ary
            end
          end
        }
        @stat.post_upd_procs << proc{
          verbose("HexView","Propagate Status#upd -> Hex::View#upd")
          upd
        }
        upd
        self
      end

      def self.sdb(id)
        file="/home/ciax/config/sdb_#{id}.txt"
        test(?r,file) && file
      end

      def upd_core
        @res[2]=b2e(@hint['udperr'])
        @res[3]=b2i(@hint['watch'])
        @res[4]=b2i(@hint['isu'])
        @res[5]=b2e(@hint['comerr'])
        @res[6]=''
        pck=0
        bin=0
        @list.each{|key,title,len,type|
          len=len.to_i
          if key === '%pck'
            pck=len
            bin=0
          elsif pck > 0
            bin+=@stat.get(key).to_i
            bin << 1
            pck-=1
            @res[6] << '%x' % bin if pck == 0
          else
            if v=@stat.get(key)
              str=get_elem(type,len,v)
              verbose("HexView","#{title}/#{type}(#{len}) = #{str}")
            else
              str='*' * len
            end
            # str can exceed specified length
            str=str[0,len]
            verbose("HexView","add '#{str}' as #{key}")
            @res[6] << str
          end
        }
        self['hex']=@res.join('')
        self
      end

      def to_x
        self['hex']
      end

      private
      def get_elem(type,len,val)
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
        str
      end

      def b2i(b) #Boolean to Integer (1,0)
        b ? '1' : '0'
      end

      def b2e(b) #Boolean to Error (E,_)
        b ? 'E' : '_'
      end
    end

    if __FILE__ == $0
      require "libinsdb"
      require "libstatus"
      begin
        stat=App::Status.new
        id=STDIN.tty? ? ARGV.shift : stat.read['id']
        stat.set_db(Ins::Db.new.get(id)).ext_file
        hint=View.new(id,0,{},stat).upd
        puts hint
      rescue InvalidID
        Msg.usage("[site] | < status_file")
      end
    end
  end
end
