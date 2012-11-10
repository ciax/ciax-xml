#!/usr/bin/ruby
require 'libfrmsv'

module Frm
  class List < Int::List
    def initialize
      super(){|ldb|
        if $opt['t']
          fint=Frm::Exe.new(ldb[:frm])
        elsif $opt['f']
          fint=Frm::Cl.new(ldb[:frm],$opt['h'])
        elsif $opt['i']
          Frm::Sv.new(ldb[:frm])
          fint=Frm::Cl.new(ldb[:frm],'localhost')
        else
          par=$opt['l'] ? ['frmsim',ldb[:frm]['site']] : []
          fint=Frm::Sv.new(ldb[:frm],par)
        end
        fint.ext_shell
      }
    end
  end
end

if __FILE__ == $0
  puts Frm::List.new.exe(ARGV)
end
