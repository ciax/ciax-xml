#!/usr/bin/ruby
require "libmcrsh"

module Mcr
  class Man < Sh::Exe
    # @< cobj,output,(intgrp),interrupt,upd_proc*
    def initialize(mdb,il)
      @mdb=Msg.type?(mdb,Db)
      self['layer']='mcr'
      self['id']=@mdb['id']
      self['total']='0'
      @mid=ServerID.new('mcr',self['total'])

      output=Msg::CmdList.new('caption' => 'Macro List','color' => 2)
      prom=Sh::Prompt.new(self,{'total' => "(0/%s)"})
      super(output,prom)

      @mg=@shdom.add_group('mcr','Switch Macro',2)

      output['[0]']='Macro Manager'
      m0=@mid.to_s
      il[m0]=self
      @mg.add_item(self['total'],'Macro Manager').reset_proc{
        raise(SelectID,m0)
      }

      @extdom=@cobj.add_extdom(@mdb).reset_proc{|item|
        num=self['total']=@mid.inc_id.id
        mkey=@mid.to_s
        msh=il[mkey]=Mcr::Sv.new(@cobj,il)
        msh.shdom['mcr']=@mg
        upd_mg(num)
        output["[#{num}]"]=msh
        @mg.add_item(num).reset_proc{
          raise(SelectID,mkey)
        }
        msh.start_bg
        raise(SelectID,mkey)
      }
    end

    private
    def upd_mg(num)
      @mg.cmdlist.keep_if{|k,v| k == '0'}
      @mg.cmdlist["1-#{num}"]='Other Macro Process'
    end
  end
end

if __FILE__ == $0
  begin
    il=Ins::List.new('mcr')
    mdb=Mcr::Db.new('ciax')
    man=Mcr::Man.new(mdb,il)
    il.shell('0')
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
