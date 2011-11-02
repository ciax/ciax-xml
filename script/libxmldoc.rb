#!/usr/bin/ruby
require "libxmlgn"

# Domain is the top node of each name spaces
class XmlDoc < Hash
  attr_reader :top,:file
  def initialize(dbname = nil,id = nil)
    @v=Msg::Ver.new("xmldoc",4)
    @domain={}
    @file=readxml(dbname,id){|e|
      @top=e
      update(e.to_h)
      e.each{|e1|
        @domain[e1.name]=e1 unless e.ns == e1.ns
      }
      @v.msg{"Domain registerd:#{@domain.keys}"}
    } if id
    return if @top
    list={}
    readxml(dbname){|e| list[e['id']]=e['label'] }
    raise SelectID,Msg::List.new.add(list).sort!.to_s
  end

  def domain(domain)
    if @domain.key?(domain)
      @domain[domain]
    else
      Xml.new
    end
  end

  private
  def readxml(dbname,id=nil)
    pre="#{ENV['XMLPATH']}/#{dbname}"
    Dir.glob("#{pre}-*.xml").each{|p|
      x=Xml.new(p)
      if id
        x.find("*[@id='#{id}']"){|e|
          yield e
          return p
        }
      else
        x.each{|e| yield e}
      end
    }
  end
end
