#!/usr/bin/ruby
require 'libfrmsv'

module Frm
  class List < Int::List
    # @< opt,(share_proc*)
    def initialize(opt=nil)
      super{|id|
        fdb=Loc::Db.new(id)[:frm]
        host='localhost'
        if @opt['l'] or @opt['e']
          par=@opt['l'] ? ['frmsim',fdb['site']] : []
          fint=Frm::Sv.new(fdb,par)
          fint=Frm::Cl.new(fdb,host) if @opt['f']
        elsif @opt['f'] or @opt['a']
          fint=Frm::Cl.new(fdb,@opt['h'])
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
  opt=Msg::GetOpts.new('e')
  puts Frm::List.new(opt).exe(ARGV)
end
