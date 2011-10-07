#!/usr/bin/ruby
require "libmsg"
class Sql < Array
  # Sql.new(Hash,String,String)
  def initialize(stat,table,dbname='ciax')
    @v=Msg::Ver.new("sql",6)
    @stat=stat
    @table=table
    @sql=["sqlite3",VarDir+"/"+dbname+".sq3"]
  end

  def create
    key=@stat.keys.join(',')
    push "create table #{@table} (time,#{key},primary key(time));"
  end

  def upd
    @v.msg{"Update:[#{@table}]"}
    key=@stat.keys.join(',')
    val=@stat.values.map{|s| "'#{s}'"}.join(',')
    push "insert into #{@table} (#{key}) values (#{val});"
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
  view=Rview.new.update_j(gets(nil))
  sql=Sql.new(view['stat'],view['id']).upd
  puts sql.to_s
end
