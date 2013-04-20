#!/usr/bin/ruby
require "libfrmlist"

module App
  class List < Interactive::List
    # @ fl,fint,list
    require "libappsv"
    def initialize
      @fl=Frm::List.new
      @fint={}
      super{|id|
        ldb=Loc::Db.new(id)
        @list=ldb.list
        fi=@fint[id]=@fl[ldb[:frm]['site_id']]
        if $opt['e'] or $opt['s'] or $opt['f']
          aint=Sv.new(ldb[:app],fi,$opt['e'])
          aint=Cl.new(ldb[:app],fi,'localhost') if $opt['c']
        elsif host=$opt['h'] or $opt['c']
          aint=Cl.new(ldb[:app],fi,host)
        else
          aint=Test.new(ldb[:app],fi)
        end
        aint.set_switch('dev',"Change Device",@list)
      }
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts App::List.new.exe(ARGV).output
end
