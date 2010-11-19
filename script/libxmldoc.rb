#!/usr/bin/ruby
require "libxmlelem"

class XmlDoc < Hash
  def initialize(db = nil ,type = nil)
    $errmsg=''
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    f=open(path)
  rescue Errno::ENOENT
    list=Array.new
    Dir.glob("#{pre}-*.xml").each{|p|
      $errmsg << XmlElem.new(open(p)).list
    }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  else
    XmlElem.new(f).each{|e|
      update(e.attr)
      e.each{|e1| self[e1.name]=e1 }
    }
  end

  def select_id(xpath,id)
    return self[xpath].selid(id)
  rescue SelectID
    $errmsg << "No such command [#{id}]\n" if id
    $errmsg << "== Command List ==\n"
    $errmsg << $!.to_s
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end
end
