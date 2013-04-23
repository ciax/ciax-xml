#!/usr/bin/ruby
require "libapplist"
require "libfrmlist"

module Ins
  class List < Sh::List
    require "libappsv"
    def initialize
      @al=App::List.new
      super
    end

    def newsh(id)
      layer,site=id.split(':')
      layer=layer.to_sym
      ldb=Loc::Db.new(site)
      site=ldb[layer]['site_id']
      case layer
      when :app
        @al[site]
      when :frm
        @al.fl[site]
      end
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new.shell(ARGV.shift)
end
