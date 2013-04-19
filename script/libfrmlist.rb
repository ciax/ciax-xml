#!/usr/bin/ruby
require 'libfrmsv'

module Frm
  class List < Interactive::List
    # @< (init_proc*)
    def initialize
      super{|id|
        fdb=Loc::Db.new(id)[:frm]
        if $opt['s'] or $opt['e']
            par=$opt['s'] ? ['frmsim',fdb['site_id']] : []
            fint=Frm::Sv.new(fdb,par)
            fint=Frm::Cl.new(fdb,'localhost') if $opt['c']
        elsif host=$opt['h'] or $opt['c'] or $opt['f']
          fint=Frm::Cl.new(fdb,host)
        else
          fint=Frm::Test.new(fdb)
        end
        fint.ext_shell{|line|
          line='set '+line.tr('=',' ') if /^[^ ]+\=/ === line
          line
        }
      }
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('e')
  puts Frm::List.new.exe(ARGV)
end
