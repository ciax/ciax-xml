#!/usr/bin/ruby
require "libmsg"
class Sql < Array
  def initialize(view)
    @v=Msg::Ver.new("sql",6)
    @stat=view['stat']
    @keys=@stat.keys.join(',')
    @id=view['id']
    @sql=["sqlite3",VarDir+"/ciax.sq3"]
  end

  def create
    push "create table #{@id} (#{@keys},primary key(time));"
  end

  def upd
    @v.msg{"Update:[#{@id}]"}
    vals=@stat.values.map{|s| "\"#{s}\""}.join(',')
    push "insert into #{@id} (#{@keys}) values (#{vals});"
  end

  def flush
    IO.popen(@sql,'w'){|f|
      f.puts "begin;"
      f.puts self
      f.puts "commit;"
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
  sql=Sql.new(view).upd
  puts sql
end
