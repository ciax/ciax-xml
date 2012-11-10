#!/usr/bin/ruby
require "libfrmlist"

module App
  class List < Int::List
    require "libappsv"
    def initialize
      $opt||={}
      @fl=Frm::List.new
      @fint={}
      super(){|ldb|
        id=ldb['id']
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
      @share_proc.add{|ldb,int|
        int.ext_shell({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
        int.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
        yield ldb['id'],int if defined? yield
      }
      @fl.share_proc.add{|ldb,int|
        int.set_switch('lay',"Change Layer",{'app'=>"App mode"})
      }
      @type='app'
      @id=id
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
      @share_proc.add{|ldb,int|
        yield ldb['id'],int if defined? yield
      }
      super
    end
  end
end

if __FILE__ == $0
  puts App::List.new.exe(ARGV)
end
