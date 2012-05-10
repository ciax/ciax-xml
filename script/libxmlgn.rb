#!/usr/bin/ruby
require "libmsg"
require "libxmlshare"
require "xml"

module Xml
  class Gnu
    extend Msg::Ver
    include Share
    def initialize(f=nil)
      Gnu.init_ver(self,4)
      case f
      when String
        test(?r,f) || raise(SelectID)
        @e=XML::Document.file(f).root
        Gnu.msg{@e.namespaces.default}
      when XML::Node
        @e=f
      when nil
        doc=XML::Document.new
        @e=doc.root=XML::Node.new('blank')
      else
        Msg.err("Parameter shoud be String or Node")
      end
    end

    def ns
      @e.namespaces.default
    end

    def to_h # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"}) 
      h=@e.attributes.to_h
      if t=text
        h['val']=t 
      end
      h
    end

    def text
      @e.each{|n|
        return n.content if n.text? && /[\S]/ === n.content
      }
      nil
    end

    # pick same ns nodes even if it is in another tree
    def find(xpath)
      Gnu.msg{"FindXpath:#{xpath}"}
      @e.doc.find("//ns:#{xpath}","ns:#{ns}").each{|e|
        Gnu.msg(1){"<#{e.name} #{e.attributes.to_h}>"}
        yield Gnu.new(e)
        Gnu.msg(-1){"</#{e.name}>"}
      }
    end

    def each
      @e.each_element{|e|
        Gnu.msg(1){"<#{e.name} #{e.attributes.to_h}>"}
        yield Gnu.new(e)
        Gnu.msg(-1){"</#{e.name}>"}
      }
    end
  end
end
