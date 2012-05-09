#!/usr/bin/ruby
# For sqlite3
require "libmsg"

# Generate SQL command string
module SqLog
  module Stat
    def self.extended(obj)
      Msg.type?(obj,Var).init
    end

    def init
      @log=[]
      @tid="#{@id}_#{@ver.to_i}"
      self
    end

    def create
      key=['time',*expand.keys].uniq.join("','")
      @v.msg{"create ('#{key}')"}
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
      @v.msg{"Update(#{@val['time']}):[#{@type}/#{@tid}]"}
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
      Msg.type?(obj,Stat).init
    end

    def init
      @sqlcmd=["sqlite3",VarDir+"/"+@type+".sq3"]
      unless check_table
        create
        save
        @v.msg{"Init/Table '#{@tid}' is created in #{@type}"}
      end
      @v.msg{"Init/Start SqLog '#{@type}' (#{@tid})"}
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

    def upd
      super
      save
      self
    end

    # Do a transaction
    def save
      super
      IO.popen(@sqlcmd,'w'){|f|
        f.puts sql
      }
      @v.msg{"Transaction complete (#{@type})"}
      @log.clear
      self
    rescue
      Msg.err(" in SQL")
    end
  end
end

if __FILE__ == $0
  require "libinsdb"
  require "libstatus"
  id=ARGV.shift
  ARGV.clear
  begin
    adb=Ins::Db.new(id).cover_app
    stat=Status.new.extend(InFile).init(id).load
    stat.extend(SqLog::Stat).upd
    puts stat.sql
  rescue UserError
    Msg.usage "[id]"
  end
  exit
end
