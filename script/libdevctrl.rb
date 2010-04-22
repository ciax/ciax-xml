#!/usr/bin/ruby
require "libdevcmd"
require "libdevstat"
require "libxmldoc"
require "libstatio"

class DevCmd
  def initialize(dev)
    begin
      ddb=XmlDoc.new('ddb',dev)
      @dc=DevCmd.new(ddb)
      @ds=DevStat.new(ddb)
    rescue RuntimeError
      puts $!
      exit 1
    end
  end

  def devcom(cmd,par=nil)
    begin
      @dc.node_with_id!(cmd)
    rescue
      puts $!
      return
    end
    begin
      @ds.node_with_id!(cmd)
    rescue
      session(par) do |ecmd|
        yield ecmd
      end
    else
      session(par) do |ecmd|
        stat=@ds.devstat(yield ecmd)
        @dc.set_var!(stat)
        return stat
      end
    end
  end
  
  private
  def session(par)
    begin
      @dc.devcmd(par) do |ecmd|
        yield ecmd
      end
    rescue
      puts $!
    end
  end
end





