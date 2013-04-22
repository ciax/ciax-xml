#!/usr/bin/ruby
require "libfrmlist"

module App
  class List < Sh::List
    # @ fl
    require "libappsv"
    def initialize
      @fl=Frm::List.new
      super
    end

    def newsh(id)
      ldb=Loc::Db.new(id)
      adb=ldb[:app]
      fi=@fl[ldb[:frm]['site_id']]
      if $opt['e'] or $opt['s'] or $opt['f']
        ash=Sv.new(adb,fi,$opt['e'])
        ash=Cl.new(adb,fi,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c']
        ash=Cl.new(adb,fi,host)
      else
        ash=Test.new(adb,fi)
      end
      ash.switch_menu('dev',"Change Device",ldb.list)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts App::List.new.exe(ARGV).output
end
