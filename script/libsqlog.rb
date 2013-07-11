#!/usr/bin/ruby
# For sqlite3
require "libmsg"

# Generate SQL command string
module CIAX
  module SqLog
    module Data
      # @ log,tid
      def self.extended(obj)
        Msg.type?(obj,Datax)
      end

      def ext_sqlog(ver=nil)
        @ver_color=9
        ver||=self['ver'].to_i
        @log=[]
        @tid="#{self['type']}_#{ver}"
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
        super
        val=expand
        key=val.keys.map{|s| s.to_s}.join(',')
        val=val.values.map{|s| s.to_s}.join(',')
        verbose("SqLog","Update(#{self['time']}):[#{self['id']}/#{@tid}]")
        @log.push "insert or ignore into #{@tid} (#{key}) values (#{val});"
        self
      end

      def sql
        (["begin;"]+@log+["commit;"]).join("\n")
      end

      def ext_exec
        extend(SqLog::Exec).ext_exec
      end

      private
      def expand
        val={'time'=>self['time']}
        @data.each{|k,v|
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
        Msg.type?(obj,Data)
      end

      def ext_exec
        @sqlcmd=["sqlite3",VarDir+"/sqlog_"+self['id']+".sq3"]
        unless check_table
          create
          save
          verbose("SqLog","Init/Table '#{@tid}' is created in #{self['id']}")
        end
        verbose("SqLog","Init/Start '#{self['id']}' (#{@tid})")
        self
      end

      # Check table existence
      def check_table
        internal("tables").split(' ').include?(@tid)
      end

      # Issue internal command
      def internal(str)
        cmd=@sqlcmd.join(' ')+" ."+str
        `#{cmd}`
      end

      # Do a transaction
      def save(data=nil,tag=nil)
        super
        unless data || tag
          IO.popen(@sqlcmd,'w'){|f|
            f.puts sql
          }
          Msg.abort("Sqlite3 input error") unless $?.success?
          verbose("SqLog","Save complete (#{self['id']})")
          @log.clear
        end
        self
      end
    end
  end

  require "libstatus"
  class Datax
    def ext_sqlog(ver=nil)
      extend(SqLog::Data).ext_sqlog(ver)
    end
  end

  if __FILE__ == $0
    require "liblocdb"
    id=ARGV.shift
    ARGV.clear
    begin
      adb=Loc::Db.new.set(id)[:app]
      stat=App::Status.new.ext_file(adb['site_id']).load
      stat.ext_sqlog.create.upd
      puts stat.sql
    rescue InvalidID
      Msg.usage "[id]"
    end
    exit
  end
end
