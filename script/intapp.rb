#!/usr/bin/ruby
require "libapplist"
require "libfrmlist"

Msg.getopts("cfh:lts")
@alist=App::List.new('localhost')
@flist=Frm::List.new
id=ARGV.shift

def shell(type,id)
  case type
  when /app/
    int=@alist[id]
    @flist[id]
  when /frm/
    int=@alist[id].fint
  end
  int.shell
end

begin
  type='app'
  ARGV.each{|i| sleep 0.3;alist[i] }
  sleep if $opt["s"]
  while cmd=shell(type,id)
    case cmd
    when 'app','frm'
      type=cmd
    else
      id=cmd
    end
  end
  rescue UserError
  Msg.usage('(opt) [id]',*$optlist)
end
