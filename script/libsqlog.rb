#!/usr/bin/ruby
# For sqlite3
require "libmsg"
require "thread"

# Generate SQL command string
module CIAX
  module SqLog
    class Upd
      attr_reader :tid,:stat
      include Msg
      def initialize(stat,ver=nil)
        @ver_color=9
        @stat=type?(stat,Hash)
        ver||=@stat['ver'].to_i
        @log=[]
        @tid="#{@stat['type']}_#{ver}"
      end

      def create
        key=['time',*expand.keys].uniq.join("','")
        verbose("SqLog","create ('#{key}')")
        @log.push "create table #{@tid} ('#{key}',primary key(time));"
        self
      end

      def add(key)
        @log.push "alter table #{@tid} add column #{key};"
        self
      end

      def upd
        val=expand
        key=val.keys.map{|s| s.to_s}.join("','")
        val=val.values.map{|s| s.to_s}.join("','")
        verbose("SqLog","Update(#{@stat['time']}):[#{@stat['id']}/#{@tid}]")
        @log.push "insert or ignore into #{@tid} ('#{key}') values ('#{val}');"
        self
      end

      def to_s
        (["begin;"]+@log+["commit;"]).join("\n")
      end

      private
      def expand
        val={'time'=>@stat['time']}
        @stat.data.each{|k,v|
          next if /type/ =~ k
          case v
          when Array
            rec_expand(k,v,val)
          else
            val[k]=v
          end
        }
        val
      end

      def rec_expand(k,v,val)
        v.size.times{|i|
          case v[i]
          when Enumerable
            rec_expand("#{k}:#{i}",v[i],val)
          else
            val["#{k}:#{i}"]=v[i]
          end
        }
        val
      end
    end

    # Execute Sql Command to sqlite3
    class Save
      # @< log,tid
      # @ sqlcmd
      include Msg
      def initialize(id)
        @sqlcmd=["sqlite3",VarDir+"/sqlog_"+id+".sq3"]
        @queue=Queue.new
        Thread.new{
          IO.popen(@sqlcmd,'w'){|f|
            verbose("SqLog","Init/Start '#{id}'")
            loop{
              sql=@queue.pop
              begin
                f.puts sql
              rescue
                Msg.abort("Sqlite3 input error\n#{sql}")
              end
            }
          }
        }
      end

      # Check table existence
      def init_table(sqlog)
        Msg.type?(sqlog,SqLog::Upd)
        unless internal("tables").split(' ').include?(sqlog.tid)
          sqlog.create
          verbose("SqLog","Init/Table '#{sqlog.tid}' is created")
        end
        sqlog.stat.upd_proc << proc{
          sqlog.upd
          @queue.push sqlog.to_s
          verbose("SqLog","Save complete")
        }
        self
      end

      # Issue internal command
      def internal(str)
        args=@sqlcmd.join(' ')+" ."+str
        `#{args}`
      end
    end
  end

  if __FILE__ == $0
    require "liblocdb"
    require "libstatus"
    id=ARGV.shift
    ARGV.clear
    begin
      adb=Loc::Db.new.set(id)[:app]
      stat=App::Status.new.ext_file(adb['site_id']).load
      sqlog=SqLog::Upd.new(stat)
      puts sqlog.create.upd
    rescue InvalidID
      Msg.usage "[id]"
    end
    exit
  end
end
