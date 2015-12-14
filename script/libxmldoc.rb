#!/usr/bin/ruby
require 'libgetopts'
require 'libdispgrp'
require 'libenumx'
require 'libxmlgn'

# Structure for Command: (doctop),<domain>,[item]
#   ADB:/adb/(app)/<command>/group/unit/[item]
#   FDB:/fdb/(frame)/<command>/[item]
#   SDB:/sdb/(symbol)/[table]
#   DDB:/ddb/(project)/[site]
#   IDB:/idb/(project)/group/[instance]
#   MDB:/mdb/(macro)/group/unit/[item]
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
        read_files(Msg.xmlfiles(@type))
        store_includes
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

      def read_files(files)
        files.each do|xml|
          verbose { 'readxml:' + ::File.basename(xml, '.xml') }
          Gnu.new(xml).each { |e| store_doc(e, @displist) }
        end.empty? && Msg.cfg_err("No XML file for #{@type}-*.xml")
      end

      def store_doc(top, grp)
        id = top['id'] # site_id or macro_proj
        grp.put_item(id, top['label'])
        item = Hashx[top: top, attr: top.to_h]
        top.each do|e1|
          if top.ns != e1.ns
            (item[:domain]||={})[e1.name.to_sym] = e1 
          elsif e1.name == 'include'
            (item[:include]||=[]) << e1['ref'] 
          else
            @subid=e1.name.to_sym
            (item[@subid]||={})[e1['id']] = e1
          end
        end
        self[id] = item
      end

      def store_includes
        each do |id, item|
          if (ary = item.delete(:include))
            ary.each { |ref| (item[@subid]||={}).update(self[ref][@subid]) }
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
