#!/usr/bin/ruby
require "libdevcmd"
require "libdevstat"
require "libxmldoc"
require "libstatio"

class Dev
  attr_reader :stat
  def initialize(dev,iocmd)
    @stat=Hash.new
    @iocmd=iocmd
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
      session(par)
    else
      @stat=@ds.devstat(session(par))
    end
  end

  private
  def session(par)
    begin
      @dc.devcmd(par) do |ecmd|
        open("|"+@iocmd,'r+') do |f|
          f.puts ecmd
          f.gets(nil)
        end
      end
    rescue
      puts $!
    end
  end
end
