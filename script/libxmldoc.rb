#!/usr/bin/ruby
require "libexenum"
require "libxmlgn"

# Domain is the top node of each name spaces
module Xml
  # xmldoc group will be named after xml filename
  # default group name is 'all' and all xmldoc will belong to this group
  # The default group specified at initialize limits the items
  # to those described in the group named file.
  # The group named file can conatin referenced item whose entity is
  # in another file.
  class Doc < ExHash
    attr_reader :top,:list
    ALL='all-list'
    @@root={}
    def initialize(type,group=nil)
      @ver_color=4
      /.+/ =~ type || Msg.cfg_err("No Db Type")
      @group=group||ALL
      verbose("XmlDoc","xmlroot:#{@@root.keys}")
      @tree=(@@root[type]||=readxml("#{ENV['XMLPATH']}/#{type}-*.xml"))
      list={}
      Msg.abort("No XML group for '#{group}' in #{type}") unless @tree.key? @group
      @tree[@group].each{|id,e|
        list[id]=e['label']
      }.empty? && raise(InvalidID)
      @list=Msg::CmdList.new({"caption" => "[id]"}).update(list).sort!
      @domain={}
      @top=nil
    end

    def set(id)
      raise(InvalidID,@list.to_s) unless @tree[@group].key?(id)
      @top=@tree[@group][id]
      update(@top.to_h)
      @top.each{|e1|
        @domain[e1.name]=e1 unless @top.ns == e1.ns
      }
      verbose("XmlDoc","Domain registerd:#{@domain.keys}")
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
      group={ALL=>{}}
      reflist=[]
      Dir.glob(glob).each{|p|
        base=File.basename(p,'.xml')
        verbose("XmlDoc","readxml:#{base}")
        fid=base.gsub(/.+-/,'')
        Gnu.new(p).each{|e|
          if ref=e['ref']
            reflist << [fid,ref]
          elsif id=e['id']
            (group[fid]||={})[id]=e if fid != id
            group[ALL][id]=e if fid != ALL
          end
        }
      }.empty? && Msg.abort("No XML file for #{glob}")
      reflist.each{|fid,id|
        (group[fid]||={})[id]=group[ALL][id] if fid != ALL
      }
      group
    end
  end
end

if __FILE__ == $0
  begin
    doc=Xml::Doc.new(ARGV.shift)
    puts doc.list
  rescue ConfigError
    Msg.usage("[type] (adb,fdb,idb,mdb,sdb)")
  end
end
