#!/usr/bin/ruby
require "rexml/document"
include REXML

class SelectID < RuntimeError ; end

class XmlRe
  include Enumerable

  def initialize(f)
    case f
    when IO
      @e=Document.new(f).root
    when Element
      @e=f
    else
      raise "Parameter shoud be IO or Element"
    end
  end

  def each(xpath=nil)
    @e.each_element(xpath){|e|
      yield XmlRe.new(e)
    }
  end

  def [](key)
    @e.attributes[key]
  end

  def to_h # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
    h={}
    @e.attributes.each{|k,v| h[k]=v }
    h
  end

  def name
    @e.name
  end

  def text
    @e.text
  end

  # select element with key=val, or display list
  def select(key,val)
    @e.each_element_with_attribute(key,val){|e|
      return XmlRe.new(e)
    } if val
    raise SelectID,list(key)
  end

  def list(key)
    inject(''){|msg,e|
      msg << " %-10s: %s\n" % [e[key],e['label']] if e[key] && e['label']
      msg
    }
  end
end
