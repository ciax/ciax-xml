#!/usr/bin/ruby
require "libfrmlist"

module App
  class List < Int::List
    # @< opt,share_proc*
    # @ fl,fint,list
    require "libappsv"
    def initialize(opt=nil)
      @fl=Frm::List.new(opt)
      @fint={}
      super{|id|
        ldb=Loc::Db.new(id)
        @list=ldb.list
        if @opt['t']
          aint=App::Test.new(ldb[:app])
        else
          @fint[id]=@fl[ldb[:frm]['site']]
          if @opt['a']
            if @opt['e'] or @opt['l'] or @opt['f']
              aint=App::Sv.new(ldb[:app],@fint[id])
              host='localhost'
            else
              host=@opt['h']
            end
            aint=App::Cl.new(ldb[:app],host)
          else
            aint=App::Sv.new(ldb[:app],@fint[id],@opt['e'])
          end
        end
        aint
      }
    end

    def shell(id)
      type='app'
      @share_proc.add{|int|
        pc={'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'}
        int.ext_shell(pc){|line|
          line='set '+line if /^[^ ]+\=/ === line
          line
        }
        int.set_switch('dev',"Change Device",@list)
        int.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
        yield id,int if defined? yield
      }
      @fl.share_proc.add{|int|
        int.set_switch('lay',"Change Layer",{'app'=>"App mode"})
      }
      super{|cmd|
        case cmd
        when 'app','frm'
          type=cmd
        else
          id=cmd
        end
        case type
        when /app/
          self[id]
        when /frm/
          @fint[id]
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
  opt=Msg::GetOpts.new('e')
  puts App::List.new(opt).exe(ARGV)
end
