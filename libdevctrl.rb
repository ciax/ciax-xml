#!/usr/bin/ruby
require "libdev"
class DevCtrl < Dev
  def setcmd(cmd)
    begin
      @doc.top_node_xpath('//cmdframe').select_id(cmd)
    rescue
      puts $!
      exit 1
    end
    @doc.node?('//ccrange') do |e|
      @var.calCc(e,@var.getStr(e))
      @doc.substitute(e,'//ccrange')
    end
  end
  def sndfrm
    @var.getStr(@doc.top_node)
  end
end
