#!/usr/bin/ruby
require "libfrmlist"

module App
  class List < Int::List
    require "libappsv"
    def initialize
      $opt||={}
      @fl=Frm::List.new
      @fint={}
      super(){|id|
        ldb=Loc::Db.new(id)
        @list=ldb.list
        if $opt['t']
          aint=App::Test.new(ldb[:app])
        else
          @fint[id]=@fl[ldb[:frm]['site']]
          if $opt['a']
            aint=App::Cl.new(ldb[:app],$opt['h'])
          else
            aint=App::Sv.new(ldb[:app],@fint[id])
          end
        end
        aint
      }
    end

    def shell(id)
      @id=id
      @type='app'
      @share_proc.add{|int|
        int.ext_shell({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
        int.set_switch('dev',"Change Device",@list)
        int.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
        yield @id,int if defined? yield
      }
      @fl.share_proc.add{|int|
        int.set_switch('lay',"Change Layer",{'app'=>"App mode"})
      }
      super{|cmd|
        case cmd
        when 'app','frm'
          @type=cmd
        else
          @id=cmd
        end
        case @type
        when /app/
          self[@id]
        when /frm/
          @fint[@id]
        end
      }
    end

    def server(ary)
      @share_proc.add{|int|
        yield @id,int if defined? yield
      }
      super
    end
  end
end

if __FILE__ == $0
  Msg.getopts("t")
  puts App::List.new.exe(ARGV)
end
