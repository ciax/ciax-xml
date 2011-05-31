#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libsymdb"

class Db < Hash
  attr_reader :command,:status,:symtbl
  def initialize(type,id)
    @doc=XmlDoc.new(type,id)
    @v=Verbose.new("#{type}/#{@doc['id']}",2)
    update(@doc)
    @command={}
    @status={}
    @symtbl=SymDb.new(@doc)
    @v.msg{"Structure:symtbl #{@symtbl}"}
  end
end
