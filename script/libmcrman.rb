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
      m0=@mid.dup
      il[m0]=self
      @mg.add_item(self['total'],'Macro Manager').reset_proc{
        raise(SelectID,m0)
      }

      @extdom=@cobj.add_extdom(@mdb).reset_proc{|item|
        mc=@mid.inc
        num=self['total']=mc[:site]
        msh=il[mc]=Mcr::Sv.new(@cobj,il)
        msh.shdom['mcr']=@mg
        @mg.cmdlist.keep_if{|k,v| k == '0'}
        @mg.cmdlist["1-#{num}"]='Other Macro Process'
        output["[#{num}]"]=item[:cmd]
        @mg.add_item(num).reset_proc{
          raise(SelectID,mc)
        }
        msh.start_bg
        raise(SelectID,mc)
      }
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
