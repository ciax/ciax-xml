#!/usr/bin/ruby
require "libmsg"
class Sql < Array
  def initialize(id,stat)
    @v=Msg::Ver.new("sql",6)
    @id=id
    @stat=stat
    @sql=["sqlite3",VarDir+"/ciax.sq3"]
  end

  def create
    key=stat.keys.join(',')
    push "create table #{@id} (#{key},primary key(time));"
  end

  def upd
    @v.msg{"Update:[#{@id}]"}
    key=@stat.keys.join(',')
    val=@stat.values.map{|s| "\"#{s}\""}.join(',')
    push "insert into #{@id} (#{key}) values (#{val});"
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
  require "json"
  abort "Usage: #{$0} [status_file]" if STDIN.tty? && ARGV.size < 1
  view=JSON.load(gets(nil))
  sql=Sql.new(view['id'],view['stat']).upd
  puts sql.to_s
end
