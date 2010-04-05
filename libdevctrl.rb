#!/usr/bin/ruby
require "libdev"
class DevCtrl < Dev
  def getStr(e)
    str=String.new
    e.elements.each do |d|
      case d.name
      when 'data'
        str << trText(d,@var.getText(d))
      else
        str << @var[d.name]
      end
    end
    str
  end
  def setcmd(cmd)
    begin
      @doc.top_node_xpath('//cmdframe').select_id(cmd)
    rescue
      puts $!
      exit 1
    end
    @doc.node?('//ccrange') do |e|
      @var.calCc(e,getStr(e))
      @doc.substitute(e,'//ccrange')
    end
  end
  def sndfrm
    getStr(@doc.top_node)
  end
end
