#!/usr/bin/ruby
# For sqlite3
require "libmsg"
require "libappstat"

class Sql < Array
  def initialize(table_id,stat)
    @v=Msg::Ver.new("sql",6)
    @tid=table_id
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

class SqlExe < Sql
  def initialize(table_id,stat,dbname='ciax')
    super(table_id,stat)
    @sql=["sqlite3",VarDir+"/"+dbname+".sq3"]
    unless check_table
      ini.flush
      @v.msg{"Init/SQL table is created"}
    end
    @v.msg{"Init/Logging Start"}
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
  sql=Sql.new(view['id'],view['stat'])
  puts sql.upd.to_s
end
