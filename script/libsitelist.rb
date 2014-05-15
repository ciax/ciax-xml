#!/usr/bin/ruby
require "libmsg"
require "libcommand"
require "libsitedb"

module CIAX
  module Site
    # Site List
    class List < Hashx
      attr_reader :init_procs
      # shdom: Domain for Shared Command Groups
      def initialize(upper=Config.new)
        upper[:ldb]||=Db.new
        @cfg=Config.new(upper)
        # initialize exe (mostly add new menu) at new key generated
        @init_procs=[proc{|exe| exe.cobj.lodom.add_group(:group_class =>JumpGrp)}]
        $opt||=GetOpts.new
      end

      def [](site)
        @site=site
        if key?(site)
          super
        else
          val=self[site]=new_val(site)
          @init_procs.each{|p| p.call(val)}
          val
        end
      end

      def server(ary)
        ary.each{|i|
          sleep 0.3
          self[i]
        }.empty? && self[nil]
        sleep
      rescue InvalidID
        $opt.usage('(opt) [id] ....')
      end

      def shell(site=nil)
        @site=site if site
        begin
          self[@site].shell
        rescue SiteJump
          @site=$!.to_s
          retry
        end
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end

      private
      # For generate Exe (allows nil)
      def new_val(site)
      end
    end

    class JumpGrp < Group
      def initialize(upper,crnt={})
        super
        @cfg['caption']='Switch Sites'
        @cfg['color']=5
        @cfg['column']=2
        update_items(@cfg[:ldb].list)
        set_proc{|ent| raise(SiteJump,ent.id)}
      end
    end
  end
end
