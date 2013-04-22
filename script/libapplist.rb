#!/usr/bin/ruby
require "libfrmlist"

module App
  class List < Sh::List
    attr_reader :fl
    require "libappsv"
    def initialize
      @fl=Frm::List.new
      super
    end

    def newsh(id)
      ldb=Loc::Db.new(id)
      adb=ldb[:app]
      fsh=@fl[ldb[:frm]['site_id']]
      if $opt['e'] or $opt['s'] or $opt['f']
        ash=Sv.new(adb,fsh,$opt['e'])
        ash=Cl.new(adb,fsh,'localhost') if $opt['c']
      elsif host=$opt['h'] or $opt['c']
        ash=Cl.new(adb,fsh,host)
      else
        ash=Test.new(adb,fsh)
      end
      ash.switch_menu('dev',"Change Device",ldb.list)
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts App::List.new.exe(ARGV).output
end
