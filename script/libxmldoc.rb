#!/usr/bin/ruby
require "libxmlgn"

class XmlDoc < Hash
  private
  def initialize(db = nil ,type = nil)
    $errmsg=''
    @db=db
    readxml(type){|e|
      self[e.name]=e
      update(e.to_h)
      e.each{|e1| self[e1.name]=e1 }
    }
  rescue SelectID
    readxml{|e| $errmsg << e.item('id') }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  def readxml(type='*')
    raise SelectID unless type
    pre="#{ENV['XMLPATH']}/#{@db}"
    path="#{pre}-#{type}.xml"
    Dir.glob(path).each{|p|
      XmlGn.new(p).each{|e|
        yield e
      }
    }.empty? && raise(SelectID)
  end

  public
  def select(domain,xpath)
    raise SelectID unless key?(domain)
    self[domain].find_each(xpath){|e|
      return e
    }
    nil
  end

  def select_id(domain,id,xpath='*')
    if key?(domain)
      return select(domain,"#{xpath}[@id='#{id}']") || raise(SelectID)
    end
  rescue SelectID
    $errmsg << "No such command [#{id}]\n" if id
    $errmsg << "== Command List ==\n"
    find_each(domain,xpath){|e|
      $errmsg << e.item('id')
    }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  def find_each(domain,xpath)
    raise SelectID unless key?(domain)
    self[domain].find_each(xpath){|e|
      yield e
    }
  end
end
