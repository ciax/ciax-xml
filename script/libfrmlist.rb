#!/usr/bin/ruby
require 'libfrmsv'

module Frm
  class List < Int::List
    def initialize
      super(){|id|
        fdb=Loc::Db.new(id)[:frm]
        if $opt['t']
          fint=Frm::Exe.new(fdb)
        elsif $opt['f']
          fint=Frm::Cl.new(fdb,$opt['h'])
        elsif $opt['i']
          Frm::Sv.new(fdb)
          fint=Frm::Cl.new(fdb,'localhost')
        else
          par=$opt['l'] ? ['frmsim',fdb['site']] : []
          fint=Frm::Sv.new(fdb,par)
        end
        fint.ext_shell
      }
    end
  end
end

if __FILE__ == $0
  Msg.getopts('t')
  puts Frm::List.new.exe(ARGV)
end
