#!/usr/bin/ruby
require "libmsg"
require "libinsdb"

# 'f' or 'a' is client
# 's' is server
# 'l' is sim by log
# 't' is check cmd only
# 'h' is specified host
module Frm
  class List < Hash
    def initialize
      $opt||={'f'=>true}
      super{|h,id|
        idb=Ins::Db.new(id)
        fdb=idb.cover_app.cover_frm
        if $opt['t']
          require "libfrmsh"
          int=Sh.new(fdb)
        elsif $opt['f'] or $opt['a']
          require "libfrmcl"
          int=Cl.new(fdb,$opt['h'])
        else
          require "libfrmsv"
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
