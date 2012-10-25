#!/usr/bin/ruby
require "libmsg"
require "liblocdb"
require "libfrmsh"

# 'l' is sim by log
# 't' is check cmd only
module Frm
  autoload :Sv,"libfrmsv"
  class Slist < Hash
    def initialize
      $opt||={}
      super(){|h,id|
        ldb=Loc::Db.new(id)
        fdb=ldb.cover_app.cover_frm[:frm]
        if $opt['t']
          int=Sh.new(fdb)
        else
          par=$opt['l'] ? ['frmsim',id] : []
          int=Sv.new(fdb,par)
        end
        int.set_switch('dev',"Change Device",ldb.list)
        h[id]=int
      }
    end
  end
end

if __FILE__ == $0
  id=ARGV.shift
  begin
    ary=Frm::Slist.new
    puts ary[id]
  rescue
    Msg.exit
  end
end
