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
        FrmCl.new(fdb,$opt['h'])
      else
          par=$opt['d'] ? ['frmsim',id] : []
        require "libfrmsv"
        FrmSv.new(fdb,par).server
      end
    }
  end
end
