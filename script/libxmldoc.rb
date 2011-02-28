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
    @doc=values.first.doc
  rescue Errno::ENOENT
    list=Array.new
    Dir.glob("#{pre}-*.xml").each{|p|
      $errmsg << XmlGn.new(p).list('id')
    }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  def select_id(domain,id)
    raise SelectID unless key?(domain)
    return self[domain].select('id',id)
  rescue SelectID
    $errmsg << "No such command [#{id}]\n" if id
    $errmsg << "== Command List ==\n"
    $errmsg << $!.to_s
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  def find_id(domain,xpath,id)
    raise SelectID unless key?(domain)
    ns=self[domain].ns
    e=@doc.find_first("//ns:#{xpath}","ns:#{ns}")
    return XmlGn.new(e).select('id',id)
  rescue SelectID
    $errmsg << "No such command [#{id}]\n" if id
    $errmsg << "== Command List ==\n"
    $errmsg << $!.to_s
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  def find_each(xpath)
    @doc.root.namespaces.default_prefix='find'
    @doc.find("//find:#{xpath}").each{|e|
      yield XmlGn.new(e)
    }
  end
end
