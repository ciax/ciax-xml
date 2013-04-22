#!/usr/bin/ruby
require "libfrmlist"

module App
  class List < Interactive::List
    # @ fl,fint,list
    require "libappsv"
    def initialize
      @fl=Frm::List.new
      super
    end

    def newint(id)
      ldb=Loc::Db.new(id)
      adb=ldb[:app]
      fi=@fl[ldb[:frm]['site_id']]
      if $opt['e'] or $opt['s'] or $opt['f']
        aint=Sv.new(adb,fi,$opt['e'])
        aint=Cl.new(adb,fi,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c']
        aint=Cl.new(adb,fi,host)
      else
        aint=Test.new(adb,fi)
      end
      aint.set_switch('dev',"Change Device",ldb.list)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts App::List.new.exe(ARGV).output
end
