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
      def initialize(type,project=nil)
        super()
        @cls_color=4
        @pfx_color=2
        @project=project
        /.+/ =~ type || Msg.cfg_err("No Db Type")
        @type=type
        @pcap='All'
        @cmdlist=CmdList.new('column' => 2)
        @projlist=CmdGrp.new('caption' => 'Project', 'column' => 2)
        Dir.glob("#{ENV['XMLPATH']}/#{type}-*.xml").each{|xml|
          verbose("XmlDoc","readxml:"+::File.basename(xml,'.xml'))
          Gnu.new(xml).each{|e|
            readproj(e)
          }
        }.empty? && Msg.cfg_err("No XML file for #{type}-*.xml")
        raise(InvalidProj,"No such Project(#{@project})\n"+@projlist.view) if @cmdlist.empty?
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
      def readproj(e)
        if e.name == 'project'
          id=e['id']
          pc=@projlist[id]=e['caption']
          @pcap=(id == @project) ? pc : nil
          e.each{|e0|
            readgrp(e0)
          }
        else
          readgrp(e)
        end
      end

      def readgrp(e)
        if e.name == 'group'
          @group=@cmdlist.new_grp(e['caption']) if @pcap
          e.each{|e0|
            readitem(e0)
          }
        else
          @group||=@cmdlist.new_grp(@pcap) if @pcap
          readitem(e)
        end
      end

      def readitem(e)
        id=e['id']
        self[id]=e
        @group[id]=e['label'] if @pcap
      end
    end
  end

  if __FILE__ == $0
    type,id=ARGV
    begin
      doc=Xml::Doc.new(type,ENV['PROJ'])
      puts doc.set(id)
    rescue InvalidProj
      Msg.usage("[type] [project] [id]")
    rescue InvalidID
      Msg.usage("[type] [project] [id]")
    rescue ConfigError
      Msg.usage("[type] (adb,fdb,idb,ddb,mdb,sdb)")
    end
  end
end
