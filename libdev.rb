#!/usr/bin/ruby
require "libxmldb"
require "libxmlvar"
class Dev
  def initialize(dev)
    @var=XmlVar.new
    begin
      @doc=XmlDb.new('ddb',dev)
    rescue
      puts $!
      exit 1
    end
  end
  def setcmd(cmd)
    begin
      @doc.select_id(cmd)
    rescue
      puts $!
      exit 1
    end
  end
end
