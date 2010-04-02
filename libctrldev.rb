#!/usr/bin/ruby
require "libxmldb"
require "libxmltxt"
class CtrlDev < String
  include XmlText
  def sndfrm(dev,cmd)
    begin
      ddb=XmlDb.new('ddb',dev)
      ddb.top_node_xpath('//cmdframe').select_id(cmd)
    rescue
      puts $!
      exit 1
    end
    ddb.node?('//ccrange') do |e|
      getStr(e).calCc(e)
      ddb.substitute(e,'//ccrange')
    end
    getStr(ddb.top_node)
  end
end
