#!/usr/bin/ruby
require "libdevcmd"
require "libdevstat"
require "libxmldoc"
require "libmodio"
require "libio"

class Dev
  include Verbose
  attr_reader :stat
  def initialize(dev,iocmd)
    begin
      ddb=XmlDoc.new('ddb',dev)
      @dc=DevCmd.new(ddb)
      @ds=DevStat.new(ddb)
    rescue RuntimeError
      puts $!
      exit 1
    end
    @stat=@ds.field
    @f=Io.new(iocmd)
  end

  def devcom(cmd,par=nil)
    begin
      @dc.node_with_id!(cmd)
    rescue
      puts $!
      return
    end
    if @ds.node_with_id!(cmd)
      @stat=@ds.devstat(session(par))
    else
      session(par)
    end
  end

  private
  def session(par)
    stat=String.new
    begin
      @dc.devcmd(par) do |ecmd|
        stat=@f.session(ecmd)
      end
    rescue
      puts $!
    end
    stat
  end
end
