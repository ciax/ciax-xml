#!/usr/bin/ruby
# For sqlite3
require "libmsg"

# Generate SQL command string
class SqLog < Array
  def initialize(type,id,ver,val)
    @v=Msg::Ver.new(self,6)
    @type=type
    @tid="#{id}_#{ver.to_i}"
    @val=Msg.type?(val,Hash)
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
    val=expand
    key=val.keys.join("','")
    val=val.values.join("','")
    @v.msg{"Update(#{@val['time']}):[#{@type}/#{@tid}]"}
    push "insert or ignore into #{@tid} ('#{key}') values ('#{val}');"
  end

  def to_s
    (["begin;"]+self+["commit;"]).join("\n")
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
module SqLog::Exec
  def self.extended(obj)
    Msg.type?(obj,SqLog)
    @sql=["sqlite3",VarDir+"/"+type+".sq3"]
    unless check_table
      ini
      save
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
  def save
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
  require "libstat"
  Msg.usage "[stat_file]" if STDIN.tty? && ARGV.size < 1
puts  stat=Stat.new.load
#  sql=SqLog.new('value',stat.id,stat.ver,stat.val)
#  puts sql.upd
end
