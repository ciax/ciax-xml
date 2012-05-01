#!/usr/bin/ruby
require "libmsg"
require "libinsdb"

# 'f' is client
# 's' is server
# 'd' is dummy(from log)
# 'h' is specified host
class IntFrms < Hash
  def initialize
    $opt||={}
    super(){|h,id|
      fdb=InsDb.new(id).cover_app.cover_frm
      if $opt['f']
        require "libfrmcl"
        Frm::Cl.new(fdb,$opt['h'])
      else
        require "libfrmsv"
        par=$opt['d'] ? ['frmsim',id] : []
        Frm::Sv.new(fdb,par).socket
      end
    }
  end
end
