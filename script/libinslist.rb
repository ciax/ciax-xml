#!/usr/bin/ruby
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
      case layer
      when 'app'
        fsh=self[['frm',fdb['site_id']]]
        sh=App.new(ldb[:app],fsh)
      when 'frm'
        sh=Frm.new(fdb)
      end
      sh.switch_menu('lay',"Change Layer",llist,[nil,sh['id']])
      sh.switch_menu('dev',"Change Device",ldb.list,[layer,nil])
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts List.new('app').shell(ARGV.shift)
end
