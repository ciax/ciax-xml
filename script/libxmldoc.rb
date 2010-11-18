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
    Dir.glob("#{pre}-*.xml").each {|p|
      addlist(XmlElem.new(open(p)))
    }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  else
    doc=XmlElem.new(f)
    doc.each{|e| self[e.name]=e }
    update(doc.to_h)
  end

  def select_id(xpath,id)
    return self[xpath].selid(id)
  rescue SelectID
    $errmsg << "No such command [#{id}]\n" if id
    $errmsg << "== Command List ==\n"
    self[xpath].each { |e| addlist(e) }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  private
  def addlist(e)
    $errmsg << " %-10s: %s\n" % [e['id'],e['label']] if e['label']
  end

end
