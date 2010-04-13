#!/usr/bin/ruby
require "libdev"
TopNode='//cmdframe'
class DevCtrl < Dev
  def devcmd
    node_with_name('ccrange') do |e|
      @ccstr=e.get_string
      e.checkcode(@ccstr)
    end
    get_string
  end

  protected
  def get_string
    str=String.new
    each do |d|
      case d.name
      when 'data'
        str << d.text
      when 'ccrange'
        str << @ccstr
      else
        str << @var[d.name]
      end
    end
    str
  end
  
  def text
    code=super
    @doc.attributes.each do |key,val|
      case key
      when 'mask'
        code=eval "#{code}#{val}"
      when 'pack'
        code=[code].pack(val)
      when 'format'
        code=val % code
      end
    end
    code.to_s
  end
end

