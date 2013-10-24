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
    verbose("FrmSim","->[#{str}]")
    IO.popen(@sqlcmd,'r+'){|f|
      f.puts str
      str=f.gets.chomp
    }
    verbose("FrmSim","<-[#{str}]")
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
      verbose("FrmSim","REWINDED")
      retry
    end
    @index=tim.to_f
    sql="select min(time),count(*) from #@tbl where time > #{tim} and dir='rcv' and cmd='#{cmd}';"
    tim,crnt=query(sql).split('|')
    verbose("FrmSim","CURRENT:[#{cmd}](#{@total-crnt.to_i}/#{@total})")
    sleep tim.to_f-@index if tim.to_f > @index
    sql="select base64 from #@tbl where time=#{tim};"
    query(sql)
  end

  def input
    select([STDIN])
    [STDIN.sysread(1024).chomp].pack("m").split("\n").join('')
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
