#!/usr/bin/ruby
require "libxmldb"
require "libxmlvar"
require "libxmltxt"
class Dev
  include XmlTxt
  def initialize(dev)
    @var=XmlVar.new
    begin
      @doc=XmlDb.new('ddb',dev)
    rescue
      puts $!
      exit 1
    end
  end
end
