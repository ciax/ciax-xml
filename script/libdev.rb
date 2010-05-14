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
    @dc.node_with_id!(cmd)
    rawcmd=@dc.devcmd(par)
    @if.save_frame(['snd',cmd,par].compact.join('_'),rawcmd)
    @ic.snd(rawcmd)
    rawrsp=@ic.rcv
    @if.save_frame("rcv_#{cmd}",rawrsp)
    @ds.node_with_id!(cmd)
    @stat=@ds.devstat(rawrsp)
  end

end
