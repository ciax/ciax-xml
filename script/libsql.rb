#!/usr/bin/ruby
# For sqlite3
require "libmsg"
require "libappstat"

class Sql < Array
  def initialize(id,ver,stat)
    @v=Msg::Ver.new(self,6)
    @tid="#{id}_#{ver.to_i}"
    @stat=Msg.type?(stat,Hash)
  end

  def ini
    key=['time',*expand.keys].uniq.join("','")
    @v.msg{"create ('#{key}')"}
    push "create table #{@tid} ('#{key}',primary key(time));"
  end

  def add(key)
    push "alter table #{@tid} add column #{key};"
  end

  def upd
    stat=expand
    key=stat.keys.join("','")
    val=stat.values.join("','")
    @v.msg{"Update:[#{@tid}] (#{@stat['time']})"}
    push "insert or ignore into #{@tid} ('#{key}') values ('#{val}');"
  end

  def to_s
    (["begin;"]+self+["commit;"]).join("\n")
  end

  private
  def expand
    stat={}
    @stat.each{|k,v|
      case v
      when Array
        rec_expand(k,v,stat)
      else
        stat[k]=v
      end
    }
    stat
  end

  def rec_expand(k,v,stat)
    v.size.times{|i|
      case v[i]
      when Enumerable
        rec_expand("#{k}:#{i}",v[i],stat)
      else
        stat["#{k}:#{i}"]=v[i]
      end
    }
    stat
  end
end

class SqLog < Sql
  def initialize(id,ver,stat,dbname='temp')
    super(id,ver,stat)
    @sql=["sqlite3",VarDir+"/"+dbname+".sq3"]
    unless check_table
      ini.flush
      @v.msg{"Init/Table '#{@tid}' is created in #{dbname}"}
    end
    @v.msg{"Init/Start '#{dbname}' (#{id}/Ver.#{ver})"}
  end

  def check_table
    internal("tables").split(' ').include?(@tid)
  end

  def internal(str)
    cmd=@sql.join(' ')+" ."+str
    `#{cmd}`
  end

  def flush
    IO.popen(@sql,'w'){|f|
      f.puts to_s
    }
    clear
  rescue
    Msg.err(" in SQL")
  end
end

if __FILE__ == $0
  require "librview"
  Msg.usage "[view_file]" if STDIN.tty? && ARGV.size < 1
  view=Rview.new.load
  sql=Sql.new(view['id'],view['ver'],view['stat'])
  puts sql.upd.to_s
end
