#!/usr/bin/ruby
require "libmsg"
require "libappstat"
class Sql < Array
  def initialize(table_id,stat,dbname='ciax')
    @v=Msg::Ver.new("sql",6)
    @tid=table_id
    @stat=Msg.type?(stat,Hash)
    @sql=["sqlite3",VarDir+"/"+dbname+".sq3"]
  end

  def create
    key=@stat.keys.join(',')
    @v.msg{"create (#{key})"}
    push "create table #{@tid} (time,#{key},primary key(time));"
  end

  def add(keys)
    push "alter table #{@tid} add (#{keys});"
  end

  def del(keys)
    push "alter table #{@tid} drop (#{keys});"
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

  def flush
    IO.popen(@sql,'w'){|f|
      f.puts to_s
    }
    clear
  rescue
    Ver.err(" in SQL")
  end
end

if __FILE__ == $0
  require "librview"
  abort "Usage: #{$0} [view_file]" if STDIN.tty? && ARGV.size < 1
  view=Rview.new.load
  sql=Sql.new(view['id'],view['stat'])
  puts sql.upd.to_s
end
