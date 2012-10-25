#!/usr/bin/ruby
require "libmsg"
require "liblocdb"
require "libfrmsh"

module Frm
  autoload :Sv,"libfrmsv"
  class Clist < Hash
    def initialize(host=nil)
      super(){|h,id|
        ldb=Loc::Db.new(id)
        fdb=ldb.cover_app.cover_frm[:frm]
        int=Cl.new(fdb,host)
        int.set_switch('dev',"Change Device",ldb.list)
        h[id]=int
      }
    end
  end
end

if __FILE__ == $0
  id=ARGV.shift
  begin
    ary=Frm::Clist.new
    puts ary[id]
  rescue
    Msg.exit
  end
end
