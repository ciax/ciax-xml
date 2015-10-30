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
        @group.to_s
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
          @group ||= Disp::Section.new(@displit)
          read_grp(e, @group)
        else
          @group ||= Disp::Group.new(@displist)
          read_doc(e, @group)
        end
      end

      def read_proj(e)
        proj = e['id']
        @projects[proj] = e
        return if @valid_proj.empty?
        return unless  @valid_proj.include?(proj) && e['include']
        @valid_proj << e['include']
      end

      def valid_proj
        return if @projects.keys.empty?
        vl = @valid_proj.empty? ? @projects.keys : @projects.keys & @valid_proj
        @group = Disp::Section.new(@displist)
        vl.each do |pid|
          proj=@projects[pid]
          sg = nil
          proj.each do |e|
            if e.name == 'group'
              sg ||= @group.put(pid,proj['caption'],true)
              read_grp(e,sg)
            else
              sg ||= @group.put(pid,proj['caption'])
              read_doc(e, sg)
            end
          end
        end
      end

      def read_grp(e, sec)
        sg = sec.put( e['id'], e['caption'])
        e.each { |e0| read_doc(e0, sg) }
      end

      def read_doc(top, grp)
        id = top['id'] # site_id or macro_proj
        grp.put(id, top['label'])
        item = Hashx[top: top, attr: top.to_h, domain: {}, property: {}]
        top.each do|e1|
          item[top.ns == e1.ns ? :property : :domain][e1.name] = e1
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
      puts doc.get(ARGV.shift).path
    rescue InvalidID
      Msg.usage('[type] [id]')
    end
  end
end
