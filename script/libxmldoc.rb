#!/usr/bin/ruby
require "libxmlgn"

# Domain is the top node of each name spaces
class XmlDoc < Hash
  attr_reader :symbol
  def initialize(dbid = nil,type = nil)
    @v=Verbose.new("Doc/#{dbid}",4)
    @symbol={}
    @domain={}
    if type && ! readxml(dbid,type){|e|
        case e.name
        when 'symbol'
          @symbol=e
        else
          update(e.to_h)
          e.each{|e1|
            @domain[e1.name]=e1 unless e.ns == e1.ns
          }
          @v.msg{"Domain registerd:#{@domain.keys}"}
        end
      }.empty?
    else
      list={}
      readxml(dbid){|e| list[e['id']]=e['label'] }
      @v.list(list)
    end
  end

  def domain(domain)
    if @domain.key?(domain)
      @domain[domain]
    else
      XmlGn.new
    end
  end

  private
  def readxml(dbid,type='*')
    pre="#{ENV['XMLPATH']}/#{dbid}"
    path="#{pre}-#{type}.xml"
    Dir.glob(path).each{|p|
      XmlGn.new(p).each{|e| # Second level
        yield e
      }
    }
  end
end
