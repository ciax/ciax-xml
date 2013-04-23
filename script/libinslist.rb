#!/usr/bin/ruby
require "libappsv"
require "libfrmsv"

module Ins
  class List < Sh::List
    def newsh(id)
      layer,site=id.split(':')
      ldb=Loc::Db.new(site)
      adb=ldb[:app]
      fdb=ldb[:frm]
      case layer
      when 'app'
        fsh=self["frm:#{fdb['site_id']}"]
        if $opt['e'] or $opt['s'] or $opt['f']
          sh=App::Sv.new(adb,fsh,$opt['e'])
          sh=App::Cl.new(adb,fsh,'localhost') if $opt['c']
        elsif host=$opt['h'] or $opt['c']
          sh=App::Cl.new(adb,fsh,host)
        else
          sh=App::Test.new(adb,fsh)
        end
      when 'frm'
        if $opt['s'] or $opt['e']
          par=$opt['s'] ? ['frmsim',fdb['site_id']] : []
          sh=Frm::Sv.new(fdb,par)
          sh=Frm::Cl.new(fdb,'localhost') if $opt['c']
        elsif host=$opt['h'] or $opt['c'] or $opt['f']
          sh=Frm::Cl.new(fdb,host)
        else
          sh=Frm::Test.new(fdb)
        end
      end
      sh.switch_menu('dev',"Change Device",ldb.list,"#{layer}:%s")
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new.shell(ARGV.shift)
end
