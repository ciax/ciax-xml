#!/usr/bin/ruby
require "libmsg"
require "libappstat"
class Sql < Array
  def initialize(table_id,stat,dbname='ciax')
    @v=Msg::Ver.new("sql",6)
    @tid=table_id
    @stat=Msg.type?(stat,AppStat)
    @sql=["sqlite3",VarDir+"/"+dbname+".sq3"]
  end

  def create
    key=@stat.keys.join(',')
    push "create table #{@tid} (time,#{key},primary key(time));"
  end

  def upd
    @v.msg{"Update:[#{@tid}]"}
    key=@stat.keys.join(',')
    val=@stat.values.map{|s| "'#{s}'"}.join(',')
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
  view=Rview.new.upd
  sql=Sql.new(view['stat'],view['id'])
  puts sql.upd.to_s
end
