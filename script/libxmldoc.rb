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
  rescue Errno::ENOENT
    list=Array.new
    Dir.glob("#{pre}-*.xml").each{|p|
      $errmsg << XmlGn.new(p).list('id')
    }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  def select_id(xpath,id)
    raise SelectID unless key?(xpath)
    return self[xpath].select('id',id)
  rescue SelectID
    $errmsg << "No such command [#{id}]\n" if id
    $errmsg << "== Command List ==\n"
    $errmsg << $!.to_s
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end
end
