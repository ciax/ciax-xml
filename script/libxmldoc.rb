#!/usr/bin/ruby
require 'libgetopts'
require 'libdispgrp'
require 'libenumx'
require 'libxmlgn'

# Structure for Command: (doctop) = @toptag
#   ADB:/adb/(app)/command/group
#   FDB:/fdb/(frame)/command/group
#   SDB:/sdb/(symbol)/table
#   DDB:/ddb/group/(site)
#   IDB:/idb/(project)/include|group
#   MDB:/mdb/(macro)/include|group
# Domain is the top node of each name spaces (different from top ns),
#   otherwise element is stored in Property
module CIAX
  # Regular Doc: accessible, display in help list
  # Hidden Doc: accessible, but not displayed in help list(sub command, etc.)
  # Invalid Doc: not accessible external, for internal refernce/include only
  module Xml
    # xmldoc group will be named after xml filename or group element
    # default group name is 'all' and all xmldoc will belong to this group
    # The default group specified at initialize limits the items
    # to those described in the group named file or element.
    # The project named file can conatin referenced item whose entity is
    # in another file.
    class Doc < Hashx
      attr_reader :top, :displist
      def initialize(type)
        super()
        @cls_color = 2
        /.+/ =~ type || Msg.cfg_err('No Db Type')
        @type = type
        @displist = Disp.new
        _read_files(Msg.xmlfiles(@type))
        _set_includes
      end

      # get generates document branch of db items(Hash),
      # which includes attribute and domains
      def get(id)
        return self[id] if key?(id)
        fail(InvalidID, "No such ID(#{id}) in #{@type}\n" + to_s)
      end

      def to_s
        @displist.to_s
      end

      private

      def _read_files(files)
        files.each do|xml|
          verbose { 'readxml:' + ::File.basename(xml, '.xml') }
          Gnu.new(xml).each { |top| _set_doc(top) }
        end.empty? && Msg.cfg_err("No XML file for #{@type}-*.xml")
      end

      def _set_doc(top)
        id = top['id'] # site_id or macro_proj
        return unless id
        case top.name
        when 'group' # ddb
          _mk_top_group(top)
        when 'app', 'frame'
          _mk_domain(top)
        when 'project', 'macro'
          _mk_sub_groups(top)
        else
          _mk_items(top)
        end
      end

      def _mk_top_group(top)
        @displist.ext_grp unless @displist.is_a? Disp::Grouping
        sub = @displist.put_grp(top['id'], top['label'])
        top.each do |e|
          _mk_items(e, sub)
        end
      end

      def _mk_domain(top)
        item = _set_item(top)
        top.each do|e1|
          tag = e1.name.to_sym
          if top.ns != e1.ns # command, status, ..
            (item[:domain] ||= {})[tag] = e1
          else # Property (stream, serial, etc.)
            item[tag] = e1.to_h
          end
        end
      end

      def _mk_sub_groups(top)
        item = _set_item(top)
        top.each do|e1|
          tag = e1.name.to_sym
          case tag
          when :include # include group
            (item[:include] ||= []) << e1['ref']
          when :group # group(mdb,adb)
            @inctag = tag
            (item[tag] ||= {})[e1['id']] = e1
          else # Property (stream, serial, etc.)
            item[tag] = e1.to_h
          end
        end
      end

      def _mk_items(top, disp = @displist)
        item = _set_item(top, disp)
        top.each do|e1|
          (item[e1.name.to_sym] ||= {})[e1['id']] = e1
        end
      end

      def _set_item(top, disp = @displist)
        id = top['id'] # site_id or macro_proj
        item = Hashx[top: top, attr: top.to_h]
        disp.put_item(id, top['label'])
        self[id] = item
      end

      def _set_includes
        each_value do |item|
          if (ary = item.delete(:include))
            ary.each { |ref| (item[@inctag] ||= {}).update(self[ref][@inctag]) }
          end
        end
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    type = ARGV.shift
    begin
      doc = Xml::Doc.new(type)
    rescue ConfigError
      Msg.usage('[type] (adb,fdb,idb,ddb,mdb,sdb)')
    end
    begin
      puts doc.get(ARGV.shift).path(ARGV)
    rescue InvalidID
      Msg.usage('[type] [id]')
    end
  end
end
