#!/usr/bin/ruby
require "libappsl"

ENV['VER']||='init/'
Msg.getopts("fh:lt")
@alist=App::Slist.new
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
