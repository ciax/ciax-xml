#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libsymdb"

class Db < Hash
  attr_reader :command,:status,:tables
  def initialize(type,id)
    @doc=XmlDoc.new(type,id)
    @v=Verbose.new("#{type}/#{@doc['id']}",2)
    update(@doc)
    self[:command]={}
    self[:status]={:label => {'time' => 'TIMESTAMP' }}
    self[:tables]=SymDb.new(@doc)
    @v.msg{"Structure:tables #{self[:tables]}"}
  end

  def to_s
    Verbose.view_struct(self)
  end
end
