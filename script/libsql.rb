#!/usr/bin/ruby
# For sqlite3
require "libmsg"
require "libappstat"

# Generate SQL command string
class Sql < Array
  def initialize(type,id,ver,stat)
    @v=Msg::Ver.new(self,6)
    @type=type
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
    @v.msg{"Update(#{@stat['time']}):[#{@type}/#{@tid}]"}
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

# Execute Sql Command to sqlite3
class SqLog < Sql
  def initialize(type,id,ver,stat)
    super
    @sql=["sqlite3",VarDir+"/"+type+".sq3"]
    unless check_table
      ini.flush
      @v.msg{"Init/Table '#{@tid}' is created in #{type}"}
    end
    @v.msg{"Init/Start Log '#{type}' (#{id}/Ver.#{ver.to_i})"}
  end

  # Check table existence
  def check_table
    internal("tables").split(' ').include?(@tid)
  end

  # Issue internal command
  def internal(str)
    cmd=@sql.join(' ')+" ."+str
    `#{cmd}`
  end

  # Do a transaction
  def flush
    IO.popen(@sql,'w'){|f|
      f.puts to_s
    }
    @v.msg{"Transaction complete (#{@type})"}
    clear
  rescue
    Msg.err(" in SQL")
  end
end

if __FILE__ == $0
  require "librview"
  Msg.usage "[view_file]" if STDIN.tty? && ARGV.size < 1
  view=Rview.new.load
  sql=Sql.new('stat',view['id'],view['ver'],view['stat'])
  puts sql.upd.to_s
end
