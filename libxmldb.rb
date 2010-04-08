#!/usr/bin/ruby
require "rexml/document"
include REXML
#TopNode required
class XmlDb
  attr_reader :type,:sel
  attr_accessor :cn
  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    begin
      @doc=Document.new(open(path)).root
    rescue
      Dir.glob("#{pre}-*.xml").each do |p|
        @doc=Document.new(open(p)).root
        listId('/*')
      end
      raise("No such a file")
    end
    @type=type
    @cn=@doc.elements[TopNode]
  end
  def e_clone(e)
    d=clone
    d.cn=e
    d
  end

  def select_id(id)
    begin
      e=@doc.elements[TopNode+"//[@id='#{id}']"] || raise
      @sel=e_clone(e)
    rescue
      listId(TopNode+'//select')
      raise("No such a command")
    end
    self
  end
  def node?(xpath)
    e=@doc.elements[TopNode+xpath]
    return unless e
    yield e_clone(e)
  end
  def each
    @cn.elements.each do |e|
      yield e_clone(e)
    end
  end
  def name
    @cn.name
  end
  def text
    @cn.text
  end
  def attr
    @cn.attributes
  end

  def trText(code)
    a=attr
    code=eval "#{code}#{a['mask']}" if a['mask']
    code=[code].pack(a['pack']) if a['pack']
    code=code.unpack(a['unpack']).first if a['unpack']
    code=a['format'] ? a['format'] % code : code
    code.to_s
  end

  def show
    puts @doc.elements[TopNode]
  end
  # Error Handling
  def listId(xpath)
    @doc.elements.each(xpath+'/[@id]') do |d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    end
  end
end
