#!/usr/bin/ruby
require 'libgetopts'
require 'libdisplay'
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
      def initialize(type,proj)
        super()
        @cls_color = 2
        @valid_list = [proj].compact
        /.+/ =~ type || Msg.cfg_err('No Db Type')
        @type = type
        @disp_list = Disp::List.new('caption' => 'Project', 'column' => 2)
        read_files(Msg.xmlfiles(@type))
        fail(InvalidProj, "No such Project(#{@valid_list})\n" + @disp_list.view) if @disp_list.empty?
      end

      # get generates document branch of db items(Hash), which includes attribute and domains
      def get(id)
        fail(InvalidID, "No such ID(#{id}) in #{@type}\n" + @disp_list.to_s) unless key?(id)
        self[id]
      end

      private

      def read_files(files)
        files.each do|xml|
          verbose { 'readxml:' + ::File.basename(xml, '.xml') }
          Gnu.new(xml).each { |e| read_proj(e) }
        end.empty? && Msg.cfg_err("No XML file for #{type}-*.xml")
      end

      def read_proj(e)
        proj = e['id']
        @disp_list[proj] ||= e['caption']
        @valid_list << e['include'] if !@valid_list.empty? && @valid_list.include?(proj) && e['include']
        e.each { |e0| read_grp(e0, ) }
      end

      def read_grp(e)
        if e.name == 'group'
          @disp_list.new_grp(e['id'],e['caption'])
          e.each { |e0| read_doc(e0,e['id']) }
        else
          grplist = @disp_list.new_grp('g0','All')
          read_doc(e, 'g0')
        end
      end

      def read_doc(top,gid)
        id = top['id']
        @disp_list.put(id,top['label'],gid)
        item = Hashx[ top: top, attr: top.to_h, domain: {} , property: {}]
        top.each do|e1|
          item[top.ns == e1.ns ? :property : :domain][e1.name] = e1
        end
        verbose { "Property registerd:#{item[:property].keys}" }
        verbose { "Domain registerd:#{item[:domain].keys}" }
        self[id] = item
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    type = ARGV.shift
    begin
      doc = Xml::Doc.new(type,PROJ)
    rescue ConfigError
      Msg.usage('[type] (adb,fdb,idb,ddb,mdb,sdb)')
    rescue InvalidProj
      (proj = ARGV.shift) && retry
      Msg.usage('[type] [project] [id]')
    end
    begin
      puts doc.get(ARGV.shift).to_v
    rescue InvalidID
      Msg.usage('[type] [project] [id]')
    end
  end
end
