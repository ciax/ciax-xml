#!/usr/bin/ruby
require "libxmlgn"

class XmlDoc < Hash
  private
  def initialize(db = nil,type = nil,usage='')
    @db=db
    @usage=usage
    readxml(type){|e|
      self[e.name]=e
      update(e.to_h)
      e.each{|e1| self[e1.name]=e1 }
    }
  rescue SelectID
    err="#{$!}"
    readxml{|e| err << e.item('id') }
    raise SelectID,err
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
  def select(domain,xpath)
    raise "No Domain" unless key?(domain)
    self[domain].find_each(xpath){|e|
      return e
    }
    nil
  end

  def select_id(domain,id,xpath='*')
    elem=select(domain,"#{xpath}[@id='#{id}']")
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
    raise "No Domain" unless key?(domain)
    self[domain].find_each(xpath){|e|
      yield e
    }
  end
end
