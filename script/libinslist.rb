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
      case layer
      when 'app'
        fsh=self[['frm',fdb['site_id']]]
        sh=App.new(ldb[:app],fsh)
      when 'frm'
        sh=Frm.new(fdb)
      end
      switch_layer(sh,'lay',"Change Layer",llist)
      switch_site(sh,'dev',"Change Device",ldb.list)
      sh
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new('app').shell(ARGV.shift)
end
