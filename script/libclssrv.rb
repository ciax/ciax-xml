#!/usr/bin/ruby
require "json"
require "libobjdb"
require "libclsdb"
require "libfrmdb"
require "libiocmd"
require "libiostat"
require "libclsobj"
require "libfrmobj"

class ClsSrv < ClsObj
  def initialize(obj,cls,iocmd)
    cdb=ClsDb.new(cls)
    fdb=FrmDb.new(cdb['frame'])
    field=IoStat.new(obj,'field')
    io=IoCmd.new(iocmd,obj,fdb['wait'],1)
    fobj=FrmObj.new(fdb,field,io)
    super(cdb,obj,field){|stm|
      fobj.request(stm)
    }
  end
end
