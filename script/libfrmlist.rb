#!/usr/bin/ruby
require 'libfrmsv'

module Frm
  class List < Interactive::List
    def newint(id)
      ldb=Loc::Db.new(id)
      fdb=ldb[:frm]
      if $opt['s'] or $opt['e']
        par=$opt['s'] ? ['frmsim',fdb['site_id']] : []
        int=Sv.new(fdb,par)
        int=Cl.new(fdb,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c'] or $opt['f']
        int=Cl.new(fdb,host)
      else
        int=Test.new(fdb)
      end
      int.set_switch('dev',"Change Device",ldb.list)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('e')
  puts Frm::List.new.exe(ARGV)
end
