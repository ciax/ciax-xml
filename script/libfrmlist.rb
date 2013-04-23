#!/usr/bin/ruby
require 'libfrmsv'

module Frm
  class List < Sh::List
    def newsh(id)
      ldb=Loc::Db.new(id)
      fdb=ldb[:frm]
      fsh=Frm.new(fdb)
      fsh.switch_menu('dev',"Change Device",ldb.list)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('e')
  puts Frm::List.new.exe(ARGV)
end
