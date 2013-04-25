#!/usr/bin/ruby
require "liblocdb"
require "libappsv"
require "libfrmsv"

module Ins
  class List < Sh::List
    def newsh(sid)
      Loc::Db.new unless sid
      ldb=Loc::Db.new(sid[:site])
      fdb=ldb[:frm]
      case sid[:layer]
      when 'app'
        fsh=self[{:layer =>'frm',:site =>fdb['site_id']}]
        sh=App.new(ldb[:app],fsh)
      when 'frm'
        sh=Frm.new(fdb)
      end
      switch_layer(sh,'lay',"Change Layer",{'frm'=>"Frm mode",'app'=>"App mode"})
      switch_site(sh,'dev',"Change Device",ldb.list)
      sh
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new('app').shell(ARGV.shift)
end
