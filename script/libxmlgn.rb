#!/usr/bin/ruby
require "xml"
require "libmsg"

class Xml
  def initialize(f=nil)
    @v=Msg::Ver.new("Xml",4)
    case f
    when String
      test(?r,f) || raise(SelectID)
      @e=XML::Document.file(f).root
      @v.msg{@e.namespaces.default}
    when XML::Node
      @e=f
    when nil
      doc=XML::Document.new
      @e=doc.root=XML::Node.new('blank')
    else
      Msg.err("Parameter shoud be String or Node")
    end
  end

  def to_s
    @e.to_s
  end

  def ns
    @e.namespaces.default
  end

  def [](key)
    @e.attributes[key]
  end

  def to_h # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
    @e.attributes.to_h
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

  # pick same ns nodes even if it is in another tree
  def find(xpath)
    @v.msg{"FindXpath:#{xpath}"}
    @e.doc.find("//ns:#{xpath}","ns:#{ns}").each{|e|
      @v.msg(1){"<#{e.name} #{e.attributes.to_h}>"}
      yield Xml.new(e)
      @v.msg(-1){"</#{e.name}>"}
    }
  end

  def each
    @e.each_element{|e|
      @v.msg(1){"<#{e.name} #{e.attributes.to_h}>"}
      yield Xml.new(e)
      @v.msg(-1){"</#{e.name}>"}
    }
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

  def node2db(id=nil)
    hash=to_h
    hash['val'] = text if text
    if id
      key=hash.delete(id)
      { key => hash }
    else
      hash
    end
  end
end
