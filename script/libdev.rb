#!/usr/bin/ruby
require "libdevcmd"
require "libdevstat"
require "libxmldoc"
require "libiocmd"

class Dev
  attr_reader :stat
  def initialize(dev,iocmd)
    begin
      doc=XmlDoc.new('ddb',dev)
      @dc=DevCmd.new(doc)
      @ds=DevStat.new(doc)
    rescue RuntimeError
      abort $!.to_s
    end
    @f=IoCmd.new(iocmd)
    @stat=@ds.field
  end
  
  def devcom(cmd,par=nil)
    begin
      @dc.node_with_id!(cmd)
    rescue
      puts $!
      return
    end
    rawcmd=@dc.devcmd(par)
    rawrsp=@f.session(rawcmd)
    if @ds.node_with_id!(cmd)
      @stat=@ds.devstat(rawrsp)
    end
  end

end
