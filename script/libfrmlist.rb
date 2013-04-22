#!/usr/bin/ruby
require 'libfrmsv'

module Frm
  class List < Interactive::List
    def newint(id)
      ldb=Loc::Db.new(id)
      fdb=ldb[:frm]
      if $opt['s'] or $opt['e']
        par=$opt['s'] ? ['frmsim',fdb['site_id']] : []
        fint=Sv.new(fdb,par)
        fint=Cl.new(fdb,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c'] or $opt['f']
        fint=Cl.new(fdb,host)
      else
        fint=Test.new(fdb)
      end
      fint.set_switch('dev',"Change Device",ldb.list)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('e')
  puts Frm::List.new.exe(ARGV)
end
