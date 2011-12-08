#!/usr/bin/ruby
# For sqlite3
require "libmsg"
require "libappstat"

class Sql < Array
  def initialize(id,ver,stat)
    @v=Msg::Ver.new(self,6)
    @tid="#{id}_v#{ver}"
    @stat=Msg.type?(stat,Hash)
  end

  def ini
    key=['time',*@stat.keys].uniq.join(',')
    @v.msg{"create (#{key})"}
    push "create table #{@tid} (#{key},primary key(time));"
  end

  def add(key)
    push "alter table #{@tid} add column #{key};"
  end

  def upd
    key=@stat.keys.join(',')
    val=@stat.values.map{|s| "'#{s}'"}.join(',')
    @v.msg{"Update:[#{@tid}] (#{@stat['time']})"}
    push "insert into #{@tid} (#{key}) values (#{val});"
  end

  def to_s
    (["begin;"]+self+["commit;"]).join("\n")
  end
end

class SqLog < Sql
  def initialize(id,ver,stat,dbname='ciax')
    super(id,ver,stat)
    @sql=["sqlite3",VarDir+"/"+dbname+".sq3"]
    unless check_table
      ini.flush
      @v.msg{"Init/SQL table is created"}
    end
    @v.msg{"Init/Logging Start (#{id}/Ver.#{ver})"}
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
