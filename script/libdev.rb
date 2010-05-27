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
    @ic=IoCmd.new(iocmd,obj||dev)
    @stat=@ds.field
  end
  
  def devcom(line)
    cmd,par=line.split(' ')
    @dc.setcmd(cmd)
    @dc.setpar(par)
    @ic.snd(@dc.devcmd,@dc.cmd_id)
    @ds.setcmd(cmd)
    @stat=@ds.devstat(@ic.rcv(@ds.cmd_id),@ic.time)
  end

end
