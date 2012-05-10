#!/usr/bin/ruby
require "libxmlgn"

# Domain is the top node of each name spaces
module Xml
  class Doc < Hash
    extend Msg::Ver
    attr_reader :top,:list
    def initialize(type)
      Doc.init_ver(self,4)
      @type=type||Msg.err("Need DB type")
      list={}
      readxml{|e| list[e['id']]=e['label'] }
      @list=Msg::CmdList.new("[id]").update(list).sort!
      @domain={}
    end

    def set(id)
      @file=readxml(id){|e|
        @top=e
        update(e.to_h)
        e.each{|e1|
          @domain[e1.name]=e1 unless e.ns == e1.ns
        }
        Doc.msg{"Domain registerd:#{@domain.keys}"}
      } if id
      raise SelectID,@list.to_s unless @top
      self
    end

    def domain?(id)
      @domain.key?(id)
    end

    def domain(id)
      if domain?(id)
        @domain[id]
      else
        Gnu.new
      end
    end

    private
    def readxml(id=nil)
      pre="#{ENV['XMLPATH']}/#{@type}"
      Dir.glob("#{pre}-*.xml").each{|p|
        x=Gnu.new(p)
        if id
          x.find("*[@id='#{id}']"){|e|
            yield e
            return p
          }
        else
          x.each{|e| yield e}
        end
      }
    end
  end
end

if __FILE__ == $0
  #  begin
  doc=Xml::Doc.new(ARGV.shift)
  puts doc.list
  #  rescue
  #    Msg.usage("[type] (adb,fdb,idb,mdb,sdb)")
  #    Msg.exit
  #  end
end
