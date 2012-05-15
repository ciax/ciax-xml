#!/usr/bin/ruby
require "libmsg"
require "libinsdb"

# 'f' or 'a' is client
# 's' is server
# 'd' is dummy(from log)
# 'h' is specified host
module Frm
  class List < Hash
    def initialize
      $opt||={}
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
          par=$opt['d'] ? ['frmsim',id] : []
          int=Sv.new(fdb,par).server
        end
        yield(int,idb.list) if defined? yield
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
