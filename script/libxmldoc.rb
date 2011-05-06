#!/usr/bin/ruby
require "libxmlgn"

class XmlDoc < Hash
  private
  def initialize(dbid = nil,type = nil)
    @v=Verbose.new("Doc",4)
    if type && ! readxml(dbid,type){|e|
        self[e.name]=e
        update(e.to_h)
        e.each{|e1| self[e1.name]=e1 }
      }.empty?
    else
      list={}
      readxml(dbid){|e| list[e['id']]=e }
      @v.list(list)
    end
  end

  def readxml(dbid,type='*')
    pre="#{ENV['XMLPATH']}/#{dbid}"
    path="#{pre}-#{type}.xml"
    Dir.glob(path).each{|p|
      XmlGn.new(p).each{|e|
        yield e
      }
    }
  end

  public
  def select_id(domain,id,xpath='*')
    elem=find_each(domain,"#{xpath}[@id='#{id}']"){|e| return e }
    return elem if elem
    err=''
    err << "No such command [#{id}]\n" if id
    err << "== Command List ==\n"
    find_each(domain,xpath){|e|
      err << e.item('id')
    }
    raise SelectID,err
  end

  def find_each(domain,xpath)
    self[domain].find_each(xpath){|e|
      yield e
    } if key?(domain)
  end
end
