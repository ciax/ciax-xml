#!/usr/bin/ruby
require "libxmlgn"

# Domain is the top node of each name spaces
class XmlDoc < Hash
  attr_reader :top
  def initialize(dbname = nil,id = nil)
    @v=Verbose.new("Doc/#{dbname}",4)
    @domain={}
    readxml(dbname,id){|e|
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
    raise SelectID,@v.add(list).to_s
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
    path="#{pre}-*.xml"
    xpath=id ? "*[@id='#{id}']" : nil
    Dir.glob(path).each{|p|
      Xml.new(p).find(xpath){|e| # Second level
        yield e
      }
    }
  end
end
