#!/usr/bin/ruby
require "libclscmd"
require "libclsstat"
require "libxmldoc"

class Cls
  attr_reader :stat,:property
  def initialize(cls)
    begin
      cdb=XmlDoc.new('cdb',cls)
      @cc=ClsCmd.new(cdb)
      @cs=ClsStat.new(cdb)
    rescue RuntimeError
      abort $!.to_s
    end
    @property=@cc.property
    @cc.set_stat!(self.stat)
  end
  
  def stat
    @cs.stat
  end

  def clscom(cmd,par=nil)
    begin
      c=@cc.node_with_id(cmd)
    rescue
      puts $!
      return
    end
    c.clscmd(par) do |ccmd|
      dstat=yield ccmd
      @cc.set_var!(dstat)
      @cs.clsstat(dstat) if dstat
    end
  end
end
