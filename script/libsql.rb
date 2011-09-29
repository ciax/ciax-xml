#!/usr/bin/ruby
require "libmsg"
class Sql < Array
  def initialize(stat)
    @v=Msg::Ver.new("sql",6)
    @stat=stat
    @keys=stat.keys.join(',')
    @id=@stat['id']
    @sql=["sqlite3",VarDir+"/ciax.sq3"]
  end

  def to_ini
    push "create table #{@id} (#{@keys},primary key(time));"
  end

  def to_ins
    vals=@stat.values.map{|s| "\"#{s}\""}.join(',')
    push "insert into #{@id} (#{@keys}) values (#{vals});"
  end

  def flush
    IO.popen(@sql,'w'){|f|
      f.puts "begin;"
      f.puts self
      f.puts "commit;"
    }
  end
end
