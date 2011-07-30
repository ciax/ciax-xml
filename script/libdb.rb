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
    @status={}
    @tables=SymDb.new(@doc)
    @v.msg{"Structure:tables #{@tables}"}
  end

  def to_s
    str=Verbose.view_struct("Root",self)
    str << Verbose.view_struct("Command",@command)
    str << Verbose.view_struct("Status",@status)
    str << Verbose.view_struct("SymTable",@tables)
  end
end
