#!/usr/bin/ruby
require "libxmldb"
class Cls < XmlDb
  def initialize(cls)
    begin
      super('cdb',cls)
    rescue
      puts $!
      exit 1
    end
  end

  def session(cmd)
    begin
      select_id(cmd)
    rescue
      puts $!
      exit 1
    end
  end
end
