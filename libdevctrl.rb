#!/usr/bin/ruby
require "libdev"
TopNode='//cmdframe'
class DevCtrl < Dev
  def getStr(e)
    str=String.new
    e.each do |d|
      case d.name
      when 'data'
        str << trText(d,@var.getText(d))
      when 'ccrange'
        str << @var.ccstr
      when 'select'
        str << getStr(@doc.sel)
      else
        str << @var[d.name]
      end
    end
    str
  end
  def sndfrm
    @doc.node?('//ccrange') do |e|
      @var.calCc(e,getStr(e))
    end
    getStr(@doc)
  end
end
