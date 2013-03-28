#!/usr/bin/ruby
require "libfrmlist"

module App
  class List < Interactive::List
    # @< opt,init_proc*
    # @ fl,fint,list
    require "libappsv"
    def initialize(opt=nil,&prc)
      @fl=Frm::List.new(opt)
      @fint={}
      super{|id|
        ldb=Loc::Db.new(id)
        @list=ldb.list
        if @opt['e'] or @opt['s'] or @opt['f']
          @fint[id]=@fl[ldb[:frm]['site_id']]
          aint=Sv.new(ldb[:app],@fint[id],@opt['e'])
          aint=Cl.new(ldb[:app],'localhost') if @opt['c']
        elsif host=@opt['h'] or @opt['c']
          aint=Cl.new(ldb[:app],host)
        else
          aint=Test.new(ldb[:app])
        end
        prc ? prc.call(aint,ldb[:app]) : aint
      }
    end

    # shell and server are exclusive
    def shell(id,&prc)
      type='app'
      @init_proc=proc{|int|
        pc={'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'}
        int.ext_shell(pc){|line|
          line='set '+line if /^[^ ]+\=/ === line
          line
        }
        int.set_switch('dev',"Change Device",@list)
        int.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
        prc.call(id,int) if prc
      }
      @fl.init_proc=proc{|int|
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

    def server(ary,&prc)
      @init_proc=proc{|int|
        prc.call(int) if prc
      }
      super
    end
  end
end

if __FILE__ == $0
  opt=Msg::GetOpts.new('et')
  puts App::List.new(opt).exe(ARGV).output
end
