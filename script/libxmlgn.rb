#!/usr/bin/ruby
require "xml"
require "libverbose"

class XmlGn
  def initialize(f)
    @v=Verbose.new("Xml",2)
    case f
    when String
      test(?r,f) || raise(SelectID)
      @e=XML::Document.file(f).root
      @v.msg{@e.namespaces.default}
    when XML::Node
      @e=f
    else
      @v.err("Parameter shoud be String or Node")
    end
  end

  def each
    @e.each_element{|e|
      @v.msg(1){"<#{e.name}>"}
      yield XmlGn.new(e)
      @v.msg(-1){"</#{e.name}>"}
    }
  end

  def [](key)
    @e.attributes[key]
  end

  def to_h # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
    @e.attributes.to_h
  end

  def to_s
    @e.to_s
  end

  def name
    @e.name
  end

  def text
    @e.each{|n|
      return n.content if n.text?
    }
    nil
  end

  def ns
    @e.namespaces.default
  end

  def find_each(xpath)
    @v.msg{"Find:#{xpath}"}
    @e.doc.find("//ns:#{xpath}","ns:#{ns}").each{|e|
      yield XmlGn.new(e)
    }
  end

  def attr2db(db,pre='')
    attr={}
    to_h.each{|k,v|
      attr[k]=yield v
    }
    id=attr.delete('id') || return
    attr.each{|k,v|
      str=pre+k
      sym=str.to_sym
      db[sym]={} unless db.key?(sym)
      db[sym][id]=v
      @v.msg{str.upcase+":[#{id}] : #{v}"}
    }
    id
  end
end
