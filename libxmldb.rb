#!/usr/bin/ruby
require "rexml/document"
include REXML
#TopNode required
class XmlDb
  attr_writer :sel
  attr_accessor :doc,:a
  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    begin
      @doc=Document.new(open(path)).elements[TopNode]
    rescue
      Dir.glob("#{pre}-*.xml").each do |p|
        @doc=Document.new(open(p)).root
        listId('/*')
      end
      raise("No such a file")
    end
    @sel=nil
    @a=@doc.attributes
  end
  def selfcp(e)
    d=clone
    d.doc=e
    d.a=e.attributes
    d.sel=@sel
    d
  end
  
  def select_id(id)
    begin
      @sel=@doc.elements[TopNode+"//[@id='#{id}']"] || raise
    rescue
      listId(TopNode+'//select')
      raise("No such a command")
    end
    self
  end

  def node?(xpath)
    e=@doc.elements[TopNode+xpath]
    return unless e
    yield selfcp(e)
    self
  end

  def each
    @doc.elements.each do |e|
      if e.name == 'select' and @sel
        @sel.elements.each do |s|
          yield selfcp(s)
        end
      else
        yield selfcp(e)
      end
    end
    self
  end

  def name
    @doc.name
  end
  def text
    @doc.text
  end
  def attr
    @doc.attributes
  end

  def trText(code)
    code=eval "#{code}#{@a['mask']}" if @a['mask']
    code=[code].pack(@a['pack']) if @a['pack']
    code=code.unpack(@a['unpack']).first if @a['unpack']
    code=@a['format'] ? @a['format'] % code : code
    code.to_s
  end

  def getText(var)
    return @doc.text unless r=@a['ref']
    if var[r]
      return var[r]
    else
      raise "No reference for [#{r}]"
    end
  end

  def calCc(str)
    chk=0
    case @a['method']
    when 'len'
      chk=str.length
    when 'bcc'
      str.each_byte do |c|
        chk ^= c 
      end
    else
      raise "No such CC method #{@a['method']}"
    end
    fmt=a['format'] || '%c'
    val=(fmt % chk).to_s
    { "#{a['var']}" => val}
  end

  # Error Handling
  def listId(xpath)
    @doc.elements.each(xpath+'/[@id]') do |d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    end
  end
end
