#!/usr/bin/ruby
# For sqlite3
require "libmsg"

# Generate SQL command string
module CIAX
  module SqLog
    class Upd
      include Msg
      def initialize(stat,ver=nil)
        @ver_color=9
        @stat=type?(stat,Datax)
        ver||=@stat['ver'].to_i
        @log=[]
        @tid="#{@stat['type']}_#{ver}"
        @stat.upd_proc << proc{upd}
        self
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

      def ext_exec
        extend(SqLog::Exec).ext_exec
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
    module Exec
      # @< log,tid
      # @ sqlcmd
      def self.extended(obj)
        Msg.type?(obj,Upd)
      end

      def ext_exec
        @sqlcmd=["sqlite3",VarDir+"/sqlog_"+@stat['id']+".sq3"]
        unless check_table
          create
          save
          verbose("SqLog","Init/Table '#{@tid}' is created in #{@stat['id']}")
        end
        verbose("SqLog","Init/Start '#{@stat['id']}' (#{@tid})")
        @elapsed=0
        @lastupd=Time.now
        @stat.save_proc << proc{save if @elapsed > 1}
        self
      end

      def upd
        # For transaction timing
        super
        @elapsed=Time.now-@lastupd
        @lastupd=Time.now
        self
      end

      # Check table existence
      def check_table
        internal("tables").split(' ').include?(@tid)
      end

      # Issue internal command
      def internal(str)
        args=@sqlcmd.join(' ')+" ."+str
        `#{args}`
      end

      # Do a transaction
      def save(data=nil,tag=nil)
        unless data || tag
          IO.popen(@sqlcmd,'w'){|f|
            f.puts to_s
          }
          Msg.abort("Sqlite3 input error\n#{to_s}") unless $?.success?
          verbose("SqLog","Save complete (#{@stat['id']})")
          @log.clear
        end
        self
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
