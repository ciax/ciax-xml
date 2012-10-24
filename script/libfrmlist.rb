#!/usr/bin/ruby
require "libmsg"
require "liblocdb"
require "libfrmsh"

# 'c' is client
# 's' is server
# 'l' is sim by log
# 't' is check cmd only
# 'h' is specified host
module Frm
  autoload :Sv,"libfrmsv"
  class List < Hash
    def initialize
      $opt||={}
      super(){|h,id|
        ldb=Loc::Db.new(id)
        fdb=ldb.cover_app.cover_frm[:frm]
        if $opt['t']
          int=Sh.new(fdb)
        elsif $opt['c'] or $opt['f']
          int=Cl.new(fdb,$opt['h'])
        else
          par=$opt['l'] ? ['frmsim',id] : []
          int=Sv.new(fdb,par).server
        end
        int.set_switch('lay',"Change Layer",{'app'=>"App mode"})
        int.set_switch('dev',"Change Device",ldb.list)
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
