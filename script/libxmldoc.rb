#!/usr/bin/ruby
require "libxmlgn"

class XmlDoc < Hash
  def initialize(db = nil ,type = nil)
    $errmsg=''
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    XmlGn.new(path).each{|e|
      self[e.name]=e
      update(e.to_h)
      e.each{|e1| self[e1.name]=e1 }
    }
  rescue SelectID
    list=Array.new
    Dir.glob("#{pre}-*.xml").each{|p|
      $errmsg << XmlGn.new(p).list('id')
    }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  def select_id(domain,id,xpath=nil)
    raise SelectID unless key?(domain)
    if xpath
      find_each(domain,xpath){|e|
        return e.select('id',id)
      }
    else
      return self[domain].select('id',id)
    end
  rescue SelectID
    $errmsg << "No such command [#{id}]\n" if id
    $errmsg << "== Command List ==\n"
    $errmsg << $!.to_s
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  def find_each(domain,xpath)
    self[domain].find_each(xpath){|e|
      yield e
    }
  end
end
