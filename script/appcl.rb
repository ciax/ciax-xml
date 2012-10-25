#!/usr/bin/ruby
require "libappcl"

ENV['VER']||='init/'
Msg.getopts("cfh:lts")
@alist=App::Clist.new
id=ARGV.shift

def shell(type,id)
  case type
  when /app/
    int=@alist[id]
  when /frm/
    int=@alist[id].fcl
  end
  int.shell
end

begin
  type='app'
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
