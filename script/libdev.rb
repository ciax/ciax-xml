#!/usr/bin/ruby
require "libdevcmd"
require "libdevstat"
require "libxmldoc"
require "libstatio"

class Dev
  attr_reader :stat
  def initialize(dev,iocmd)
    @stat=Hash.new
    begin
      @f=open("|"+iocmd,'r+')
      ddb=XmlDoc.new('ddb',dev)
      @dc=DevCmd.new(ddb)
      @ds=DevStat.new(ddb)
    rescue RuntimeError
      puts $!
      exit 1
    ensure
      at_exit { @f.close }
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
      session(par)
    else
      @stat=@ds.devstat(session(par))
    end
  end

  private
  def session(par)
    begin
      @dc.devcmd(par) do |ecmd|
        @dc.v.msg "Send #{ecmd.dump}"
        @f.puts ecmd
        stat=@f.gets(nil)
        @dc.v.msg "Recv #{stat.dump}" 
      end
    rescue
      puts $!
    end
    stat
  end
end
