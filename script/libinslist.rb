#!/usr/bin/ruby
require "libappsv"
require "libfrmsv"

module Ins
  class List < Sh::List
    def newsh(id)
      layer,site=id.to_s.split(':')
      ldb=Loc::Db.new(site)
      adb=ldb[:app]
      fdb=ldb[:frm]
      case layer
      when 'app'
        fsh=self["frm:#{fdb['site_id']}"]
        sh=App.new(adb,fsh)
        llist={'frm'=>"Frm mode"}
      when 'frm'
        sh=Frm.new(fdb)
        llist={'app'=>"App mode"}
      end
      sh.switch_menu('lay',"Change Layer",llist,"%s:#{sh['id']}")
      sh.switch_menu('dev',"Change Device",ldb.list,"#{layer}:%s")
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new.shell(ARGV.shift)
end
