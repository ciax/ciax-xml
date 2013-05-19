#!/usr/bin/ruby
require "libmcrsh"

module Mcr
  class List < Sh::List
    def initialize(mdb,il)
      @il=Msg.type?(il,Ins::Layer)
      cmdlist=Msg::CmdList.new('caption' => 'Macro List','color' => 2)
      cmdlist['0']='Macro Manager'
      super(cmdlist,'0')
      self['0']=Man.new(mdb,self)
    end

    def newmcr(cobj)
      num=keys.size.to_s
      msh=self[num]=Mcr::Sv.new(cobj,@il)
      msh['total']=num
      msh.prompt['total']="[#{num}/%s]"
      msh.shdom.replace @shdom
      @shdom['id'].cmdlist.delete_if{|k,v| /^1-/ === k}
      @shdom['id'].cmdlist["1-#{num}"]='Other Macro Process'
      @shdom['id'].add_item(num).reset_proc{
        raise(SelectID,num)
      }
      msh
    end
  end

  class Man < Sh::Exe
    # @< cobj,output,upd_proc*
    def initialize(mdb,mlist)
      @mdb=Msg.type?(mdb,Db)
      @mlist=Msg.type?(mlist,List)
      self['layer']='mcr'
      self['id']=@mdb['id']
      self['total']='0'

      output=Msg::CmdList.new('caption' => 'Macro List','color' => 2)
      output['[0]']='Macro Manager'
      prom=Sh::Prompt.new(self,{'total' => "[0/%s]"})
      super(output,prom)
      @shdom.replace @mlist.shdom
      @shdom['id'].add_item('0','Macro Manager').reset_proc{
        raise(SelectID,'0')
      }
      @svdom.ext_svdom(@mdb).reset_proc{|item|
        msh=@mlist.newmcr(@cobj)
        output["[#{self['total']}]"]=msh
        msh.start_bg
        raise(SelectID,self['total'])
      }
    end
  end
end

if __FILE__ == $0
  begin
    il=Ins::Layer.new('mcr')
    mdb=Mcr::Db.new.set('ciax')
    man=Mcr::List.new(mdb,il)
    man.shell
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
