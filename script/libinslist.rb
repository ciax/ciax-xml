#!/usr/bin/ruby
require "liblocdb"
require "libfrmsv"
require "libappsv"
require "libhexsh"

module Ins
  class List < Sh::List
    def newsh(sid)
      Loc::Db.new unless sid
      ldb=Loc::Db.new(sid[:site])
      case sid[:layer]
      when 'hex'
        ash=self[ldb.sid('app')]
        sh=Hex.new(ldb[:app],ash)
      when 'app'
        fsh=self[ldb.sid('frm')]
        sh=App.new(ldb[:app],fsh)
      when 'frm'
        sh=Frm.new(ldb[:frm])
      end
      switch_layer(sh,'lay',"Change Layer",{'frm'=>"Frm mode",'app'=>"App mode",'hex'=>"Hex mode"})
      switch_site(sh,'dev',"Change Device",ldb.list)
      sh
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new('app').shell(ARGV.shift)
end
