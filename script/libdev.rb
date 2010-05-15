#!/usr/bin/ruby
require "libdevcmd"
require "libdevstat"
require "libxmldoc"
require "libiocmd"
require "libiofile"

class Dev
  attr_reader :stat
  def initialize(dev,iocmd,obj=nil)
    begin
      doc=XmlDoc.new('ddb',dev)
      @dc=DevCmd.new(doc)
      @ds=DevStat.new(doc)
    rescue RuntimeError
      abort $!.to_s
    end
    @ic=IoCmd.new(iocmd)
    @if=IoFile.new(obj||dev)
    @stat=@ds.field
  end
  
  def devcom(line)
    cmd,par=line.split(' ')
    @dc.setcmd(cmd)
    @dc.setpar(par)
    cmdframe=@dc.devcmd
    @if.log_frame(@dc.cmd_id,cmdframe)
    @ic.snd(cmdframe)
    rspframe=@ic.rcv
    time=Time.now
    @ds.setcmd(cmd)
    @if.log_frame(@ds.cmd_id,rspframe,time)
    @stat=@ds.devstat(rspframe,time)
  end

end

