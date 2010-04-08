#!/usr/bin/ruby
require "libdev"
TopNode='//cmdframe'
class DevCtrl < Dev
  def getStr
    str=String.new
    each do |d|
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
    node?('//ccrange') do |e|
      @ccstr=e.getStr
      @var.update(e.calCc(@ccstr))
    end
    getStr
  end
end
