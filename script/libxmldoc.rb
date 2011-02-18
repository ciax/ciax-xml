#!/usr/bin/ruby
require "libxmlre"

class XmlDoc < Hash
  def initialize(db = nil ,type = nil)
    $errmsg=''
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    f=open(path)
  rescue Errno::ENOENT
    list=Array.new
    Dir.glob("#{pre}-*.xml").each{|p|
      $errmsg << XmlRe.new(open(p)).list('id')
    }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  else
    XmlRe.new(f).each{|e|
      self[e.name]=e
      update(e.to_h)
      e.each{|e1| self[e1.name]=e1 }
    }
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
