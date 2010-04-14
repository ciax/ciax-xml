#!/usr/bin/ruby
require "libxmldb"
class Obj < XmlDb
  def initialize(obj)
    begin
      super('odb',obj)
    rescue
      puts $!
      exit 1
    end
  end
end
