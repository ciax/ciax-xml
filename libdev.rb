#!/usr/bin/ruby
require "libxmldb"
class Dev < XmlDb
  def initialize(dev,cmd)
    @var=Hash.new
    begin
      super('ddb',dev)
      select_id(cmd)
    rescue
      puts $!
      exit 1
    end
  end
end
