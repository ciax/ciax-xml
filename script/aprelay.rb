#!/usr/bin/ruby
require "libstat"
require "libiocmd"
require "libascpck"
require "libinteract"

id,iocmd,port=ARGV

begin
  @stat=Stat.new
  @io=IoCmd.new(iocmd)
  @ap=AscPck.new(id,@stat)
rescue SelectID
  abort "Usage: aprelay [obj] [iocmd] (port)\n#{$!}"
end

Interact.new(port||['>']){|line|
  case line
  when nil
    puts
    line='interrupt'
    @ap.issue
  when ''
    line='stat'
  else
    @ap.issue
  end
  @io.snd(line)
  time,str=@io.rcv
  begin
    @stat.update_j(str)
  rescue
  end
  @ap.upd
}
