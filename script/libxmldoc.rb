#!/usr/bin/ruby
require 'libgetopts'
require 'libdisp'
require 'libenumx'
require 'libxmlgn'

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
      attr_reader :top, :displist
      def initialize(type, project = nil)
        super()
        @cls_color = 2
        @project = [project]
        /.+/ =~ type || Msg.cfg_err('No Db Type')
        @type = type
        @pcap = 'All'
        @displist = Disp::List.new('column' => 2)
        @projlist = Disp::Group.new('caption' => 'Project', 'column' => 2)
        files = Dir.glob("#{ENV['XMLPATH']}/#{type}-*.xml")
        files.each{|xml|
          verbose { 'readxml:' + ::File.basename(xml, '.xml') }
          Gnu.new(xml).each{|e|
            @project << e['include'] if @project.include?(e['id']) and e['include']
          }
        }.empty? && Msg.cfg_err("No XML file for #{type}-*.xml")
        # Two pass reading for refering
        files.each{|xml|
          Gnu.new(xml).each { |e| readproj(e) }
        }
        raise(InvalidProj, "No such Project(#{@project})\n" + @projlist.view) if @displist.empty?
      end

      # set generates document branch of db items(Hash), which includes attribute and domains
      def set(id)
        raise(InvalidID, "No such ID(#{id}) in #@type\n" + @displist.to_s) unless key?(id)
        top = self[id]
        item = { :top => top, :attr => top.to_h, :domain => {} }
        top.each{|e1|
          item[:domain][e1.name] = e1 unless top.ns == e1.ns
        }
        verbose { "Domain registerd:#{item[:domain].keys}" }
        item
      end

      private
      def readproj(e)
        if e.name == 'project'
          id = e['id']
          pc = @projlist[id] = e['caption']
          @pcap = @project.include?(id) ? pc : nil
          e.each{|e0|
            readgrp(e0)
          }
        else
          readgrp(e)
        end
      end

      def readgrp(e)
        if e.name == 'group'
          @group = @displist.new_grp(e['caption']) if @pcap
          e.each{|e0|
            readitem(e0)
          }
        else
          @group ||= @displist.new_grp(@pcap) if @pcap
          readitem(e)
        end
      end

      def readitem(e)
        id = e['id']
        self[id] = e
        @group[id] = e['label'] if @pcap
      end
    end
  end

  if __FILE__ == $0
    type = ARGV.shift
    proj = nil
    begin
      doc = Xml::Doc.new(type, proj)
    rescue ConfigError
      Msg.usage('[type] (adb,fdb,idb,ddb,mdb,sdb)')
    rescue InvalidProj
      (proj = ARGV.shift) && retry
      Msg.usage('[type] [project] [id]')
    end
    begin
      puts doc.set(ARGV.shift)
    rescue InvalidID
      Msg.usage('[type] [project] [id]')
    end
  end
end
