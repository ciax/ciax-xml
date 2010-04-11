#!/usr/bin/ruby
require "libdev"
TopNode='//cmdframe'
class DevCtrl < Dev
  def devcmd
    node?('//ccrange') do |e|
      @ccstr=e.get_string
      @var.update(e.calc_cc(@ccstr))
    end
    get_string
  end

  protected
  def get_string
    str=String.new
    each do |d|
      case d.name
      when 'data'
        str << d.tr_text(d.text)
      when 'ccrange'
        str << @ccstr
      else
        str << @var[d.name]
      end
    end
    str
  end
end
