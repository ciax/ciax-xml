#!/usr/bin/ruby
require "libdevcmd"
require "libdevstat"
require "libxmldoc"
require "libcmdio"

class Dev
  attr_reader :stat
  def initialize(dev,iocmd)
    begin
      ddb=XmlDoc.new('ddb',dev)
      @dc=DevCmd.new(ddb)
      @ds=DevStat.new(ddb)
    rescue RuntimeError
      abort $!.to_s
    end
    @f=CmdIo.new(iocmd)
  end
  
  def stat
    @ds.field
  end

  def devcom(cmd,par=nil)
    begin
      @dc.node_with_id!(cmd)
    rescue
      puts $!
      return
    end
    @dc.devcmd(par) do |ecmd|
      stat=@f.session(ecmd)
      if @ds.node_with_id!(cmd)
        @ds.devstat(stat)
      end
    end
  end

end
