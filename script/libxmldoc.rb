#!/usr/bin/ruby
require "libxmlgn"

class XmlDoc < Hash
  private
  def initialize(db = nil,type = nil,usage='')
    @db=db
    @usage=usage
    @v=Verbose.new("Doc",4)
    readxml(type){|e|
      self[e.name]=e
      update(e.to_h)
      e.each{|e1| self[e1.name]=e1 }
    }
  rescue SelectID
    list={}
    readxml{|e| list[e['id']]=e }
    @v.list(list,"#{$!}")
  end

  def readxml(type='*')
    raise SelectID,@usage unless type
    pre="#{ENV['XMLPATH']}/#{@db}"
    path="#{pre}-#{type}.xml"
    Dir.glob(path).each{|p|
      XmlGn.new(p).each{|e|
        yield e
      }
    }.empty? && raise(SelectID,@usage)
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
    return unless key?(domain)
    self[domain].find_each(xpath){|e|
      yield e
    }
  end
end
