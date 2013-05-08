#!/usr/bin/ruby
require "liblocdb"
require "libfrmsh"
require "libappsv"
require "libhexsh"

module Ins
  class List < Sh::List
    def newsh(skey)
      Loc::Db.new unless skey
      sid=ServerID.new.upd(skey)
      ldb=Loc::Db.new(sid.id)
      case sid.layer
      when 'hex'
        ash=self[ldb.sid('app').to_s]
        sh=Hex.new(ldb[:app],ash)
      when 'app'
        fsh=self[ldb.sid('frm').to_s]
        sh=App.new(ldb[:app],fsh)
      when 'frm'
        sh=Frm.new(ldb[:frm])
      end
      switch_layer(sh,'lay',"Change Layer",{'frm'=>"Frm mode",'app'=>"App mode",'hex'=>"Hex mode"})
      switch_id(sh,'dev',"Change Device",ldb.list)
      sh
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new('app').shell(ARGV.shift)
end
