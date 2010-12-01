#!/usr/bin/ruby
require "rexml/document"
include REXML

class SelectID < RuntimeError ; end

class XmlElem
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

  def each
    @e.each_element{|e|
      yield XmlElem.new(e)
    }
  end

  def [](key)
    @e.attributes[key]
  end

  def attr # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
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

  # select element with key=val, or key='*', or display list
  def select(key,val)
    if val
      @e.each_element_with_attribute(key,val){|e|
        return XmlElem.new(e)
      }
      @e.each_element_with_attribute(key,'*'){|e|
        return XmlElem.new(e)
      }
    end
    raise SelectID,list(key)
  end

  def list(key)
    inject(''){|msg,e|
      if e[key] && e['label']
        msg << " %-10s: %s\n" % [e[key],e['label']]
      end
      msg
    }
  end
end
