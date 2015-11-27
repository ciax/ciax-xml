#!/usr/bin/ruby
require 'libgetopts'
require 'libdisp'
require 'libenumx'
require 'libxmlgn'

# Domain is the top node of each name spaces
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
      def initialize(type, proj)
        super()
        @cls_color = 2
        @valid_proj = [proj].compact
        /.+/ =~ type || Msg.cfg_err('No Db Type')
        @type = type
        @projects = Hashx.new
        @displist = Disp.new
        @displist.put_grp
        @level = 0
        read_files(Msg.xmlfiles(@type))
        valid_proj
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
          Gnu.new(xml).each { |e| read_xml(e) }
        end.empty? && Msg.cfg_err("No XML file for #{@type}-*.xml")
      end

      def read_xml(e)
        case e.name
        when 'project'
          read_proj(e)
        when 'group'
          store_grp(e, @displist.put_sec)
        else
          store_doc(e, @displist)
        end
      end

      def read_proj(e)
        pid = e['id']
        @projects[pid] = e
        return if @valid_proj.empty?
        return unless  @valid_proj.include?(pid) && e['include']
        @valid_proj << e['include']
      end

      def valid_proj
        return if @projects.keys.empty?
        vkeys = @valid_proj & @projects.keys
        vl = vkeys.empty? ? @projects.keys : vkeys
        pl = vl.map { |pid| @projects[pid] }
        pl.each { |proj| store_proj(proj, @displist.put_sec) }
      end

      def store_proj(proj, sec)
        pid = proj['id']
        cap = proj['caption']
        proj.each do |e|
          if e.name == 'group'
            store_grp(e, sec.put_sec(pid, cap))
          else
            store_doc(e, sec.put_grp(pid, cap))
          end
        end
      end

      def store_grp(e, sec)
        sg = sec.put_grp(e['id'], e['caption'])
        e.each { |e0| store_doc(e0, sg) }
      end

      def store_doc(top, grp)
        id = top['id'] # site_id or macro_proj
        grp.put_item(id, top['label'])
        item = Hashx[top: top, attr: top.to_h, domain: {}, property: {}]
        top.each do|e1|
          item[top.ns == e1.ns ? :property : :domain][e1.name.to_sym] = e1
        end
        self[id] = item
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    type = ARGV.shift
    begin
      doc = Xml::Doc.new(type, PROJ)
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
