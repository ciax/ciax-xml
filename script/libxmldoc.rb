#!/usr/bin/ruby
require "libcmdlist"
require "libenumx"
require "libxmlgn"

# Domain is the top node of each name spaces
module CIAX
  module Xml
    # xmldoc group will be named after xml filename
    # default group name is 'all' and all xmldoc will belong to this group
    # The default group specified at initialize limits the items
    # to those described in the group named file.
    # The group named file can conatin referenced item whose entity is
    # in another file.
    class Doc < Hashx
      attr_reader :top,:list
      @@root={}
      def initialize(type,group=nil)
        super()
        @index={}
        @captions={}
        @cls_color=4
        @pfx_color=2
        /.+/ =~ type || Msg.cfg_err("No Db Type")
        verbose("XmlDoc","xmlroot:#{@@root.keys}")
        @tree=(@@root[type]||=readxml("#{ENV['XMLPATH']}/#{type}-*.xml"))
        @list=CmdGrp.new
        if group
          raise(InvalidGrp,"No such Group(#{group}) #{@tree.keys}") unless @tree.key?(group)
          grp=[group]
        else
          grp=@tree.keys
        end
        grp.each{|gid|
          idx={}
          @tree[gid].each{|id,e|
            idx[id]=e['label']
          }.empty? && raise(InvalidID)
          @list.add_grp({"caption" => "[#{@captions[gid]}]"}).update(idx).sort!
        }
        @domain={}
        @top=nil
      end

      def set(id)
        raise(InvalidID,"No such ID(#{id})\n"+@list.to_s) unless @list.key?(id)
        @top=@index[id]
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
        group={}
        reflist=[]
        caption=nil
        Dir.glob(glob).each{|p|
          base=::File.basename(p,'.xml')
          verbose("XmlDoc","readxml:#{base}")
          fid=base.gsub(/.+-/,'')
          Gnu.new(p).each{|e|
            if e.name == 'group'
              gdb=group[e['id']]={}
              @captions[e['id']]=e['caption']||e['id']
              e.each{|e0|
                id=e0['id']
                gdb[id]=e0
                @index[id]=e0
              }
            elsif ref=e['ref']
              reflist << [fid,ref]
              @captions[fid]=fid.upcase
            elsif id=e['id']
              (group['all']||={})[id]=e
              @captions['all']='ALL'
              @index[id]=e
            end
          }
        }.empty? && Msg.abort("No XML file for #{glob}")
        reflist.each{|fid,id|
          (group[fid]||={})[id]=@index[id]
        }
        group
      end
    end
  end

  if __FILE__ == $0
    begin
      doc=Xml::Doc.new(ARGV.shift,ARGV.shift)
      puts doc.list
    rescue InvalidGrp
      Msg.usage("[type] [group]")
    rescue ConfigError
      Msg.usage("[type] (adb,fdb,idb,mdb,sdb)")
    end
  end
end
