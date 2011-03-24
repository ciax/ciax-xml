#!/usr/bin/ruby
require "libxmlgn"

class XmlDoc < Hash
  private
  def initialize(db = nil ,type = nil)
    $errmsg=''
    @db=db
    readxml(type){|e0|
      e0.each{|e1|
        self[e1.name]=e1
        update(e1.to_h)
        e1.each{|e2| self[e2.name]=e2 }
      }
    }
  rescue SelectID
    readxml{|e| $errmsg << e.list('id') }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  def readxml(type='*')
    raise SelectID unless type
    pre="#{ENV['XMLPATH']}/#{@db}"
    path="#{pre}-#{type}.xml"
    Dir.glob(path).each{|p|
      yield(XmlGn.new(p))
    }
  end

  public
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
