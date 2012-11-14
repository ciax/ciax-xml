#!/usr/bin/ruby
require 'libfrmsv'

module Frm
  class List < Int::List
    def initialize
      super(){|id|
        fdb=Loc::Db.new(id)[:frm]
        host='localhost'
        if $opt['l']
          par=['frmsim',fdb['site']]
          fint=Frm::Sv.new(fdb,par)
        elsif $opt['e']
          fint=Frm::Sv.new(fdb)
        else
          fint=Frm::Exe.new(fdb)
          host=$opt['h']
        end
        fint=Frm::Cl.new(fdb,host) if $opt['f']
        fint.ext_shell
      }
    end
  end
end

if __FILE__ == $0
  Msg.getopts('e')
  puts Frm::List.new.exe(ARGV)
end
