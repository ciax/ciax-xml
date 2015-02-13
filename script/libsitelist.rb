#!/usr/bin/ruby
require "libdatax"
require "libsitedb"

module CIAX
  module Site
    # Site List
    class List < DataH
      # shdom: Domain for Shared Command Groups
      def initialize(layer=nil)
        @layer=layer||'wat'
        @cfg=Config.new("list_site")
        super('site',{},@cfg[:dataname]||'list')
        @cfg[:site_list]=self
        @site_cfgs={}
        @db=Db.new
        verbose("List","Initialize")
        $opt||=GetOpts.new
      end

      # id = "layer:site"
      def get(id)
        add(id) unless @data.key?(id)
        super
      end

      def exe(args) # As a individual cui command
        id="#{@layer}:#{args.shift}"
        get(id).exe(args,'local')
      end

      def server(ary)
        ary.each{|site|
          sleep 0.3
          get("#{@layer}:#{site}")
        }.empty? && get(@layer)
        sleep
      rescue InvalidID
        $opt.usage('(opt) [id] ....')
      end

      def ext_shell
        extend(Shell)
      end

      private
      def add(id)
        layer,site=id.split(':')
        site_cfg=(@site_cfgs[site]||=Config.new("site_#{site}",@cfg).update('id' => site,:site_db =>@db.set(site),:site_stat => Prompt.new))
        exe=$layers[layer].new(site_cfg)
        set(id,exe)
        exe
      end

      def cap(type)
        {'caption'=>"Switch #{type}s",'color'=>5,'column'=>2 }
      end

      def get_site(ent)
        ldb=ent.cfg[:site_db]
        ldb["#{ent.id}_site"]||ldb['app_site']
      end

      def layer_list
        h={}
        $layers.keys.each{|key|
          h[key]=key.capitalize+' layer'
        }
        h
      end
    end

    module Shell
      def self.extended(obj)
        Msg.type?(obj,List)
      end

      def shell(site)
        id="#{@layer}:#{site}"
        begin
          get(id).shell
        rescue Jump
          id=$!.to_s
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end

      private
      def add(id)
        add_jump(super)
      end

      def add_jump(exe)
        jg=exe.cfg[:jump_groups]||=[]
        # Switch site
        jg << Group.new(exe.cfg,cap('site')).set_proc{|ent|
          raise(Jump,"#{ent.layer}:#{ent.id}")
        }.update_items(@db.list)
        # Switch layer
        jg << Group.new(exe.cfg,cap('layer')).set_proc{|ent|
          raise(Jump,"#{ent.id}:#{get_site(ent)}")
        }.update_items(layer_list)
        # JumpGroup is set to Domain
        exe.ext_shell
        jg.each{|grp|
          exe.cobj.lodom.join_group(grp)
        }
        exe
      end

      class Jump < LongJump; end
    end

    if __FILE__ == $0
      require "libhexexe"
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        puts List.new.ext_shell.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
