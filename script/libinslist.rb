#!/usr/bin/ruby
require "libappsv"
require "libfrmsv"

module Ins
  class List < Sh::List
    def newsh(id)
      site,layer=id.to_s.split(':')
      layer||='app'
      ldb=Loc::Db.new(site)
      fdb=ldb[:frm]
      llist={'frm'=>"Frm mode",'app'=>"App mode"}
      llist.delete(layer)
      case layer
      when 'app'
        fsh=self["#{fdb['site_id']}:frm"]
        sh=App.new(ldb[:app],fsh)
      when 'frm'
        sh=Frm.new(fdb)
      end
      sh.switch_menu('lay',"Change Layer",llist,"#{sh['id']}:%s")
      sh.switch_menu('dev',"Change Device",ldb.list,"%s:#{layer}")
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new.shell(ARGV.shift)
end
