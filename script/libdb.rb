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
    @command={}
    @status={:label => {'time' => 'TIMESTAMP' }}
    @tables=SymDb.new(@doc)
    @v.msg{"Structure:tables #{@tables}"}
  end

  def to_s
    str=Verbose.view_struct(self,"Root")
    str << Verbose.view_struct(@command,"Command")
    str << Verbose.view_struct(@status,"Status")
    str << Verbose.view_struct(@tables,"SymTable")
  end
end
