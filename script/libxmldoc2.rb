#!/usr/bin/ruby
require 'libdispgrp'
require 'libenumx'
require 'ox'

# Structure for Command: (top: listed in disp), <doclist: separated top-doc>
#   ADB:/adb/(app)/<command>/group/unit/item
#   FDB:/fdb/(frame)/<command>/group/item
#   SDB:/sdb/(symbol)/<table>/pattern
#   CDB:/cdb/(alias)/<top>/unit|item
#   DDB:/ddb/group/(site)/field
#   IDB:/idb/project/include|group/(site)/include|<alias>/unit/item
#   MDB:/mdb/(macro)/include|<group>/unit/item
#   HDB:/hdb/(hexpack)/pack/field
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
      def initialize(type, proj = nil)
        super()
        /.+/ =~ type || Msg.args_err('No Db Type')
        @type = type
        @proj = proj
        @displist = Disp.new
        ___read_files(Msg.xmlfiles(@type))
        ___set_includes
      end

      # get generates document branch of db items(Hash),
      # which includes attribute and domains
      def get(id)
        super { id_err(id, @type, self) }
      end

      def to_s
        @displist.to_s
      end

      private

      def ___read_files(files)
        files.each do |xmlfile|
          verbose { 'readxml:' + ::File.basename(xmlfile, '.xml') }
          begin
            Ox.load_file(xmlfile).each { |doc| ___mk_db(doc) }
          rescue InvalidARGS
            show_err
          end
        end.empty? && Msg.cfg_err("No XML file for #{@type}-*.xml")
      end

      def ___mk_db(doc)
        case doc.value
        when 'idb'
          ___mk_project(doc.project)
        when 'ddb'
          __mk_group(doc.group)
        when 'cdb'
          __set_item(doc.alias)
        when 'hdb'
          __set_item(doc.hexpack)
        else # sdb, adb, fdb, mdb
          __mk_sub_db(doc)
        end
      end

      # Includable (instance)
      def ___mk_project(doc)
        pid = doc.attributes['id']
        incprj = [pid]
        @valid_proj = incprj if @proj == pid
        grp = (@grps ||= Hashx.new)[pid] = []
        # doc may have <include> or <group>
        doc.each { |ele| ___include_proj(ele, grp, incprj) }
      end

      def ___include_proj(ele, grp, incprj)
        case ele.value.to_sym
        when :include # include project
          incprj.push(ele.attributes['ref'])
        when :group # group(mdb,adb)
          grp << ele.attributes['id']
          __mk_group(ele)
        end
      end

      # Takes second level (use group for display only)
      def __mk_group(ele)
        @displist.ext_grp unless @displist.is_a? Disp::Grouping
        att=ele.attributes
        sub = @displist.put_grp(att['id'], att['label'])
        ele.each('site') { |e| __mk_sub_db(e, sub) }
      end

      # Includable (macro)
      def __mk_sub_db(ele, sub = @displist)
        item = __set_item(ele, sub)
        ele.each do |e| # e.value can be include or group
          ___include_grp(e, item, e.attributes[:xmlns]) # ele.ns != e.ns)
        end
      end

      def ___include_grp(e, item, c_or_s)
        tag = e.value.to_sym
        case tag
        when :include # include group
          item.get(tag) { [] } << e.attributes['ref']
        when :group # group(mdb,adb)
          item.get(tag) { Hashx.new }[e.attributes['id']] = e
        else # Command, Status(different ns), Property (stream, serial, etc.)
          item[tag] = c_or_s ? e : e.attributes
        end
      end

      # set single item to self
      def __set_item(ele, disp = @displist)
        att = ele.attributes
        id = att['id'] # site_id or macro_proj
        item = Hashx[top: ele, attr: att]
        disp.put_item(id, att['label'])
        self[id] = item
      end

      # Include will be done for //group
      def ___set_includes
        ___upd_valid
        each_value do |item|
          next unless (ary = item.delete(:include))
          ary.each do |ref|
            item.get(:group) { Hashx.new }.update(self[ref][:group])
          end
        end
      end

      def ___upd_valid
        return unless @valid_proj
        vp = @valid_proj.map { |proj| @grps[proj] }.flatten
        vk = vp.map { |gid| @displist.sub[gid] }.flatten
        @displist.valid_keys.replace(vk)
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    GetOpts.new('[type] (adb,fdb,idb,ddb,mdb,cdb,sdb,hdb)') do |opt, args|
      doc = Xml::Doc.new(args.shift)
      opt.getarg('[type] [id]') do |_o, ar|
        puts doc.get(ar.shift).path(ar)
      end
    end
  end
end
