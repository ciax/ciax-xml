#!/usr/bin/ruby
require "rexml/document"
include REXML
#TopNode required
class XmlDb
  attr_reader :type,:sel
  attr_accessor :cn,:a
  def initialize(db = nil ,type = nil)
    if db.class == Element
      @cn=db
      @a=db.attributes
    else
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
      @a=@cn.attributes
    end
  end

  def select_id(id)
    begin
      e=@doc.elements[TopNode+"//[@id='#{id}']"] || raise
      @sel=XmlDb.new(e)
    rescue
      listId(TopNode+'//select')
      raise("No such a command")
    end
    self
  end
  def node?(xpath)
    e=@doc.elements[TopNode+xpath]
    return unless e
    yield XmlDb.new(e)
    self
  end
  def each
    @cn.elements.each do |e|
      yield XmlDb.new(e)
    end
    self
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
    code=eval "#{code}#{@a['mask']}" if @a['mask']
    code=[code].pack(@a['pack']) if @a['pack']
    code=code.unpack(@a['unpack']).first if @a['unpack']
    code=@a['format'] ? @a['format'] % code : code
    code.to_s
  end

  def getText(var)
    return @cn.text unless r=@a['ref']
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
