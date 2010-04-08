#!/usr/bin/ruby
require "libxmldb"
class Dev
  def initialize(dev,cmd)
    @var=Hash.new
    begin
      @doc=XmlDb.new('ddb',dev).select_id(cmd)
    rescue
      puts $!
      exit 1
    end
  end
end
