#!/usr/bin/ruby
require 'libdispgrp'
require 'libenumx'
require 'libxmlre'

# Structure for Command: (top: listed in disp), <doclist: separated top-doc>
#   ADB:/adb/(app)/<command>/group/unit/item
#   FDB:/fdb/(frame)/<command>/group/item
#   SDB:/sdb/(symbol)/<table>/pattern
#   CDB:/cdb/(alias)/<top>/unit|item
#   DDB:/ddb/group/(site)/field
#   IDB:/idb/project/include|group/(instance)/include|<alias>/unit/item
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
        _read_files_(Msg.xmlfiles(@type))
        _set_includes_
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

      def _read_files_(files)
        files.each do |xml|
          verbose { 'readxml:' + ::File.basename(xml, '.xml') }
          begin
            Elem.new(xml).each { |top| _mk_db_(top) }
          rescue InvalidARGS
            show_err
          end
        end.empty? && Msg.cfg_err("No XML file for #{@type}-*.xml")
      end

      def _mk_db_(top)
        case top.name
        when 'project' # idb
          _mk_project_(top)
        when 'group' # ddb
          _mk_group(top)
        when 'alias', 'hexpack' # cdb,hdb
          _set_item(top)
        else # sdb, adb, fdb, mdb
          _mk_sub_db(top)
        end
      end

      # Includable (instance)
      def _mk_project_(top)
        pid = top['id']
        incprj = [pid]
        @valid_proj = incprj if @proj == pid
        grp = (@grps ||= Hashx.new)[pid] = []
        # g.name is include or group
        top.each { |gdoc| _include_proj_(gdoc, grp, incprj) }
      end

      def _include_proj_(gdoc, grp, incprj)
        tag = gdoc.name.to_sym
        case tag
        when :include # include project
          incprj.push(gdoc['ref'])
        when :group # group(mdb,adb)
          grp << gdoc['id']
          _mk_group(gdoc)
        end
      end

      # Takes second level (use group for display only)
      def _mk_group(gdoc)
        @displist.ext_grp unless @displist.is_a? Disp::Grouping
        sub = @displist.put_grp(gdoc['id'], gdoc['label'])
        gdoc.each { |e| _mk_sub_db(e, sub) }
      end

      # Includable (macro)
      def _mk_sub_db(top, sub = @displist)
        item = _set_item(top, sub)
        top.each do |e| # e.name can be include or group
          _include_grp_(e, item, top.ns != e.ns)
        end
      end

      def _include_grp_(e, item, c_or_s)
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
      def _set_item(top, disp = @displist)
        id = top['id'] # site_id or macro_proj
        item = Hashx[top: top, attr: top.to_h]
        disp.put_item(id, top['label'])
        self[id] = item
      end

      # Include will be done for //group
      def _set_includes_
        _upd_valid_
        each_value do |item|
          next unless (ary = item.delete(:include))
          ary.each do |ref|
            item.get(:group) { Hashx.new }.update(self[ref][:group])
          end
        end
      end

      def _upd_valid_
        return unless @valid_proj
        vp = @valid_proj.map { |proj| @grps[proj] }.flatten
        vk = vp.map { |gid| @displist.sub[gid] }.flatten
        @displist.valid_keys.replace(vk)
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    opt = GetOpts.new('[type] (adb,fdb,idb,ddb,mdb,cdb,sdb,hdb)') do |_o, args|
      @doc = Xml::Doc.new(args.shift)
    end
    opt.getarg('[type] [id]') do |_o, args|
      puts @doc.get(args.shift).path(args)
    end
  end
end
