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
    super(){|h,id| init(id)}
  end

  private
  def init(id)
    fdb=InsDb.new(id).cover_app.cover_frm
    if $opt['f']
      require "libfrmcl"
      return FrmCl.new(fdb,$opt['h'])
    elsif $opt['d']
      par=['frmsim',id]
    else
      par=[]
    end
    require "libfrmsv"
    FrmSv.new(fdb,par).server
  end
end
