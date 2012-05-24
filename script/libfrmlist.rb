#!/usr/bin/ruby
require "libmsg"
require "libinsdb"

# 'c' is client
# 's' is server
# 'l' is sim by log
# 't' is check cmd only
# 'h' is specified host
module Frm
  autoload :Sh,"libfrmsh"
  autoload :Cl,"libfrmcl"
  autoload :Sv,"libfrmsv"
  class List < Hash
    def initialize(proj=nil)
      $opt||={}
      super(){|h,id|
        idb=Ins::Db.new(id,proj)
        fdb=idb.cover_app.cover_frm
        if $opt['t']
          int=Sh.new(fdb)
        elsif $opt['c'] or $opt['f']
          int=Cl.new(fdb,$opt['h'])
        else
          par=$opt['l'] ? ['frmsim',id] : []
          int=Sv.new(fdb,par).server
        end
        int.cmdlist.add_group('dev',"Change Device",idb.list)
        h[id]=int
      }
    end
  end
end

if __FILE__ == $0
  id=ARGV.shift
  begin
    ary=Frm::List.new
    puts ary[id]
  rescue
    Msg.exit
  end
end
