#!/usr/bin/ruby
# For sqlite3
require "libmsg"

# Generate SQL command string
module SqLog
  module Var
    extend Msg::Ver
    def self.extended(obj)
      init_ver('SqLog',9)
      Msg.type?(obj,Var).init
    end

    def init
      @log=[]
      @tid="#{@type}_#{@ver.to_i}"
      self
    end

    def create
      key=['time',*expand.keys].uniq.join("','")
      Var.msg{"create ('#{key}')"}
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
      key=val.keys.join("','")
      val=val.values.join("','")
      Var.msg{"SqLog/Update(#{@val['time']}):[#{@id}/#{@tid}]"}
      @log.push "insert or ignore into #{@tid} ('#{key}') values ('#{val}');"
      self
    end

    def sql
      (["begin;"]+@log+["commit;"]).join("\n")
    end

    private
    def expand
      val={}
      @val.each{|k,v|
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
    def self.extended(obj)
      Msg.type?(obj,Var).init
    end

    def init
      @sqlcmd=["sqlite3",VarDir+"/sqlog_"+@id+".sq3"]
      unless check_table
        create
        save
        Var.msg{"Init/Table SqLog '#{@tid}' is created in #{@id}"}
      end
      Var.msg{"Init/Start SqLog '#{@id}' (#{@tid})"}
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
        Var.msg{"SqLog/Save complete (#{@id})"}
        @log.clear
      end
      self
    end
  end
end

class Var
  def ext_sqlog
    extend(SqLog::Var)
    extend(SqLog::Exec)
  end
end

if __FILE__ == $0
  require "libinsdb"
  require "libstatus"
  id=ARGV.shift
  ARGV.clear
  begin
    adb=Ins::Db.new(id).cover_app
    stat=Status::Var.new.ext_file(adb).load
    stat.extend(SqLog::Var).upd
    puts stat.sql
  rescue UserError
    Msg.usage "[id]"
  end
  exit
end
