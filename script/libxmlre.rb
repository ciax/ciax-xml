#!/usr/bin/ruby
require "libverbose"
require "rexml/document"
include REXML

class Xml
  def initialize(f=nil)
    @v=Verbose.new("Xml",4)
    case f
    when String
      test(?r,f) || raise(SelectID)
      @e=Document.new(open(f)).root
      @v.msg{@e.namespace}
    when Element
      @e=f
    when nil
      @e=Element.new
    else
      raise "Parameter shoud be String or Element"
    end
  end

  def ns
    @e.namespaces
  end

  def to_h # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
    h={}
    @e.attributes.each{|k,v| h[k]=v }
    h
  end

  def text
    @e.text
  end

  def each(xpath=nil)
    @e.each_element(xpath){|e|
      @v.msg(1){"<#{e.name}>"}
      yield Xml.new(e)
      @v.msg(-1){"</#{e.name}>"}
    }
  end

  # Common with LIBXML,REXML
  def to_s
    @e.to_s
  end

  def [](key)
    @e.attributes[key]
  end

  def name
    @e.name
  end

  def map
    ary=[]
    each{|e|
      ary << (yield e)
    }
    ary
  end

  def attr2db(db,id='id')
    # <xml id='id' a='1' b='2'> => db[:a][id]='1', db[:b][id]='2'
    raise "Param should be Hash" unless Hash === db
    attr={}
    to_h.each{|k,v|
      attr[k] = defined?(yield) ? (yield v) : v
    }
    key=attr.delete(id) || return
    attr.each{|str,v|
      sym=str.to_sym
      db[sym]={} unless db.key?(sym)
      db[sym][key]=v
      @v.msg{"ATTRDB:"+str.upcase+":[#{key}] : #{v}"}
    }
    key
  end
end
