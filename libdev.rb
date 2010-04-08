#!/usr/bin/ruby
require "libxmldb"
require "libxmlvar"
class Dev
  def initialize(dev,cmd)
    @var=XmlVar.new
    begin
      @doc=XmlDb.new('ddb',dev)
      @doc.select_id(cmd)
    rescue
      puts $!
      exit 1
    end
  end
end
