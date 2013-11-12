#!/usr/bin/ruby
require "thread"
require "libmsg"
# Device simulator by SqLog

class LogRing
  include CIAX::Msg
  attr_reader :index,:max
  def initialize(id)
    @logary=[{}]
    @index=0
    @sqlcmd=["sqlite3",ENV['HOME']+"/.var/sqlog_"+id+".sq3"]
    @tbl=query('.tables').split(/ /).grep(/^stream/).sort.last || raise("No Stream table")
    @total=query("select count(*) from #@tbl where dir='rcv';").to_i
    @ver_color=1
  end

  def query(str)
    verbose("DevSim","->[#{str}]")
    IO.popen(@sqlcmd,'r+'){|f|
      f.puts str
      str=f.gets.chomp
    }
    verbose("DevSim","<-[#{str}]")
    str
  end

  def find_next(str)
    begin
      sql="select min(time),cmd from #@tbl where time > #@index and base64='#{str}';"
      ans=query(sql)
      tim,cmd=ans.split('|')
      raise if tim.empty?
    rescue
      raise("NO record for #{str}") if @index==0
      @index=0
      verbose("DevSim",color("LINE:REWINDED",3))
      retry
    end
    @index=tim.to_i
    sql="select min(time),count(*) from #@tbl where time > #{tim} and dir='rcv';"
    tim,crnt=query(sql).split('|')
    wait=tim.to_i > @index ? [tim.to_i-@index,1000].min.to_f/1000 : 0
    verbose("DevSim",color("LINE:[#{cmd}](#{@total-crnt.to_i}/#{@total})<#{'%.3f' % wait}>",2))
    sleep wait
    sql="select base64 from #@tbl where time=#{tim};"
    query(sql)
  end

  def input
    select([STDIN])
    [STDIN.sysread(1024)].pack("m").split("\n").join('')
  end

end

Msg.usage("[id] (ver)") if ARGV.size < 1
id=ARGV.shift
ver=ARGV.shift
ARGV.clear

logv=LogRing.new(id)
begin
  while base64=logv.input
    if str=logv.find_next(base64)
      STDOUT.syswrite(str.unpack("m").first)
    end
  end
rescue EOFError
end
