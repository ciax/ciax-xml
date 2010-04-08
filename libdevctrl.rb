#!/usr/bin/ruby
require "libdev"
TopNode='//cmdframe'
class DevCtrl < Dev
  def getStr(e)
    str=String.new
    e.each do |d|
      case d.name
      when 'data'
        str << d.trText(d.getText(@var))
      when 'ccrange'
        str << @ccstr
      else
        str << @var[d.name]
      end
    end
    str
  end
  def sndfrm
    @doc.node?('//ccrange') do |e|
      @ccstr=getStr(e)
      @var.update(e.calCc(@ccstr))
    end
    getStr(@doc)
  end
end
