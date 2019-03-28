#!/usr/bin/env ruby
require 'libdispgrp'
require 'libhashx'
require 'libxmlox'

# Structure for Command: [top: listed in disp], <doclist: separated top-doc>
#   ADB:/adb/[app]/<command>/group/unit/item
#   FDB:/fdb/[frame]/<command>/group/item
#   SDB:/sdb/[symbol]/<table>/pattern
#   CDB:/cdb/[alias]/<top>/unit|item
#   DDB:/ddb/group/[site]/field
#   IDB:/idb/project/include|group/[site]/<command>/unit/item
#   MDB:/mdb/[macro]/include|<group>/unit/item
#   HDB:/hdb/[hexpack]/pack/field
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
      attr_reader :top, :disp_dic
      def initialize(type, proj = nil)
        super()
        /.+/ =~ type || Msg.args_err('No Db Type')
        @type = type
        @proj = proj
        @disp_dic = Disp::Index.new
        ___read_files(Msg.xmlfiles(@type))
        ___set_includes
        # get generates document branch of db items(Hash),
        # which includes attribute and domains
        self.default_proc = proc { |_hash, id| id_err(id, @type, self) }
      end

      def to_s
        @disp_dic.to_s
      end

      private

      def ___read_files(files)
        files.each do |xmlfile|
          verbose { 'readxml:' + ::File.basename(xmlfile, '.xml') }
          begin
            Elem.new(xmlfile).each { |top| ___mk_db(top) }
          rescue InvalidARGS
            show_err
          end
        end.empty? && Msg.cfg_err("No XML file for #{@type}-*.xml")
      end

      def ___mk_db(top)
        case top.name
        when 'project' # idb
          ___mk_project(top)
        when 'group' # ddb
          __mk_group(top)
        when 'alias', 'hexpack' # cdb,hdb
          __set_item(top)
        else # sdb, adb, fdb, mdb
          __mk_sub_db(top)
        end
      end

      # Includable (instance)
      def ___mk_project(top)
        pid = top['id']
        incprj = [pid]
        @valid_proj = incprj if @proj == pid
        grp = (@grps ||= Hashx.new)[pid] = []
        # g.name is include or group
        top.each { |gdoc| ___include_proj(gdoc, grp, incprj) }
      end

      def ___include_proj(gdoc, grp, incprj)
        tag = gdoc.name.to_sym
        case tag
        when :include # include project
          incprj.push(gdoc['ref'])
        when :group # group(mdb,adb)
          grp << gdoc['id']
          __mk_group(gdoc)
        end
      end

      # Takes second level (use group for display only)
      def __mk_group(gdoc)
        @disp_dic.ext_grp unless @disp_dic.is_a? Disp::Grouping
        gatt = gdoc.to_h
        return if gatt[:enable] == 'false'
        sub = @disp_dic.add_grp(gatt.delete(:id), gatt.delete(:label))
        gdoc.each { |e| __mk_sub_db(e, sub, gatt.dup) }
      end

      # Includable (macro)
      def __mk_sub_db(top, sub = @disp_dic, attr = Hashx.new)
        item = __set_item(top, sub, attr) || return
        top.each do |e| # e.name can be include or group
          ___include_grp(e, item, top.ns != e.ns)
        end
      end

      def ___include_grp(e, item, c_or_s)
        tag = e.name.to_sym
        case tag
        when :include # include group
          item.get(tag) { [] } << e['ref']
        when :group # group(mdb,adb)
          item.get(tag) { Hashx.new }[e['id']] = e
        else # Command, Status(different ns), Property (stream, serial, etc.)
          item[tag] = c_or_s ? e : e.to_h
        end
      end

      # set single item to self
      def __set_item(top, disp = @disp_dic, attr = Hashx.new)
        return if top['enable'] == 'false'
        id = top['id'] # site_id or macro_proj
        item = Hashx[top: top, attr: attr.update(top.to_h)]
        disp.put_item(id, top['label'])
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
        vk = vp.map { |gid| @disp_dic.sub[gid] }.flatten
        @disp_dic.valid_keys.replace(vk)
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    Opt::Get.new('[type] (adb,fdb,idb,ddb,mdb,cdb,sdb,hdb)') do |opt, args|
      doc = Xml::Doc.new(args.shift)
      opt.getarg('[type] [id]') do |_o, ar|
        puts doc.get(ar.shift).path(ar)
      end
    end
  end
end
