#!/usr/bin/ruby
require 'libfrmsv'

module Frm
  class List < Sh::List
    def newint(id)
      ldb=Loc::Db.new(id)
      fdb=ldb[:frm]
      if $opt['s'] or $opt['e']
        par=$opt['s'] ? ['frmsim',fdb['site_id']] : []
        fsh=Sv.new(fdb,par)
        fsh=Cl.new(fdb,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c'] or $opt['f']
        fsh=Cl.new(fdb,host)
      else
        fsh=Test.new(fdb)
      end
      fsh.set_switch('dev',"Change Device",ldb.list)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('e')
  puts Frm::List.new.exe(ARGV)
end
