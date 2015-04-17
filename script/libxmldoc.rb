#!/usr/bin/ruby
require "libcmdlist"
require "libenumx"
require "libxmlgn"

# Domain is the top node of each name spaces
module CIAX
  module Xml
    # xmldoc group will be named after xml filename or group element
    # default group name is 'all' and all xmldoc will belong to this group
    # The default group specified at initialize limits the items
    # to those described in the group named file or element.
    # The project named file can conatin referenced item whose entity is
    # in another file.
    class Doc < Hashx
      attr_reader :top,:cmdlist
      def initialize(type,group=nil)
        super()
        @attrs={}
        @captions={}
        @cls_color=4
        @pfx_color=2
        /.+/ =~ type || Msg.cfg_err("No Db Type")
        @type=type
        @groups=readxml("#{ENV['XMLPATH']}/#{type}-*.xml")
        @cmdlist=CmdList.new('column' => 2)
        if group
          raise(InvalidGrp,"No such Group(#{group}) #{@groups.keys}") unless @groups.key?(group)
          grp=[group]
        else
          grp=@groups.keys
        end
        grp.each{|gid|
          idx={}
          @groups[gid].each{|id,e|
            idx[id]=e['label']
          }.empty? && raise(InvalidID)
          cap=(@attrs[gid]||{})['caption']
          @cmdlist.new_grp(cap).update(idx).sort!
        }
      end

      # set generates document branch of db items(Hash), which includes attribute and domains
      def set(id)
        raise(InvalidID,"No such ID(#{id}) in #@type\n"+@cmdlist.to_s) unless key?(id)
        top=self[id]
        item={:top => top,:attr => top.to_h,:domain => {}}
        top.each{|e1|
          item[:domain][e1.name]=e1 unless top.ns == e1.ns
        }
        verbose("XmlDoc","Domain registerd:#{item[:domain].keys}")
        item
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
            if e.name == 'group' || e.name == 'project'
              gdb=group[e['id']]={}
              @attrs[e['id']]=e.to_h
              e.each{|e0|
                id=e0['id']
                gdb[id]=e0
                self[id]=e0
              }
            elsif ref=e['ref']
              reflist << [fid,ref]
              @attrs[fid]={'caption' => fid.upcase}
            elsif id=e['id']
              (group['all']||={})[id]=e
              @attrs['all']={'caption' => 'ALL'}
              self[id]=e
            end
          }
        }.empty? && Msg.abort("No XML file for #{glob}")
        reflist.each{|fid,id|
          (self[fid]||={})[id]=self[id]
        }
        group
      end
    end
  end

  if __FILE__ == $0
    type,grp,id=ARGV
    begin
      doc=Xml::Doc.new(type,grp)
      puts doc.set(id)
    rescue InvalidGrp
      Msg.usage("[type] [group] [id]")
    rescue InvalidID
      Msg.usage("[type] [group] [id]")
    rescue ConfigError
      Msg.usage("[type] (adb,fdb,idb,ddb,mdb,sdb)")
    end
  end
end
