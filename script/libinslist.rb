#!/usr/bin/ruby
require "liblocdb"
require "libappsv"
require "libfrmsv"

module Ins
  class List < Sh::List
    def newsh(id)
      Loc::Db.new unless id
      layer,site=id
      ldb=Loc::Db.new(site)
      fdb=ldb[:frm]
      llist={'frm'=>"Frm mode",'app'=>"App mode"}
      sid=Sh::ServerID.new(self,'frm',fdb['site_id'])
      case layer
      when 'app'
        fsh=sid.getsh
        sh=App.new(ldb[:app],fsh)
      when 'frm'
        sh=Frm.new(fdb)
      end
      sh.switch_menu('lay',"Change Layer",llist,sid.siteonly(sh['id']))
      sh.switch_menu('dev',"Change Device",ldb.list,sid.layeronly(layer))
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new('app').shell(ARGV.shift)
end
