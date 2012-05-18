#!/usr/bin/ruby
require "libmsg"
require "libxmlgn"

# Domain is the top node of each name spaces
module Xml
  # xmldoc group will be named after xml filename
  # default group name is 'all' and all xmldoc will belong to this group
  # The default group specified at initialize limits the items
  # to those described in the group named file.
  # The group named file can conatin referenced item whose entity is
  # in another file.
  class Doc < Hash
    extend Msg::Ver
    attr_reader :top,:list
    def initialize(type,group=nil)
      Doc.init_ver(self,4)
      /.+/ =~ type || Msg.err("No Db Type")
      @group=group||'all'
      @tree=readxml("#{ENV['XMLPATH']}/#{type}-*.xml")
      list={}
      @tree[@group].each{|id,e|
        list[id]=e['label']
      }.empty? && raise(SelectID)
      @list=Msg::CmdList.new("[id]").update(list).sort!
      @domain={}
      @top=nil
    end

    def set(id)
      raise SelectID,@list.to_s unless @tree[@group].key?(id)
      @top=@tree[@group][id]
      update(@top.to_h)
      @top.each{|e1|
        @domain[e1.name]=e1 unless @top.ns == e1.ns
      }
      Doc.msg{"Domain registerd:#{@domain.keys}"}
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
    def readxml(glob)
      group={'all'=>{}}
      reflist=[]
      Dir.glob(glob).each{|p|
        fid=File.basename(p,'.xml').gsub(/.+-/,'')
        Gnu.new(p).each{|e|
          if ref=e['ref']
            reflist << [fid,ref]
          elsif id=e['id']
            (group[fid]||={})[id]=e if fid != id
            group['all'][id]=e if fid != 'all'
          end
        }
      }
      reflist.each{|fid,id|
        group[fid][id]=group['all'][id] if fid != 'all'
      }
      group
    end
  end
end

if __FILE__ == $0
  begin
    doc=Xml::Doc.new(ARGV.shift)
    puts doc.list
  rescue UserError
    Msg.usage("[type] (adb,fdb,idb,mdb,sdb)")
  end
end
