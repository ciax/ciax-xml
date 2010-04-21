#!/usr/bin/ruby
require "libdevctrl"
require "libdevstat"
require "libxmldoc"
require "libstatio"

class DevExe
  def initialize(dev)
    begin
      ddb=XmlDoc.new('ddb',dev)
      @dc=DevCtrl.new(ddb)
      @ds=DevStat.new(ddb)
    rescue RuntimeError
      puts $!
      exit 1
    end
  end

  def devcom(cmd,par=nil)
    @dc.node_with_id!(cmd)
    @ds.node_with_id!(cmd)
    stat=nil
    @dc.devctrl(par) do |ecmd|
      stat=ds.devstat(yield ecmd)
      dc.set_var!(stat)
    end
    stat
  end
end
