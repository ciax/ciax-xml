#!/usr/bin/ruby
require "libdatax"
require "libsitedb"

module CIAX
  module Site
    # Site List
    class List < DataH
      # shdom: Domain for Shared Command Groups
      def initialize(top_layer=nil)
        @layer=top_layer||$layers.keys.last||abort("No Layer")
        @cfg=Config.new("list_site")
        super('site',{},@cfg[:dataname]||'list')
        @cfg[:site_list]=self
        @site_cfgs={} # site specific configs
        @db=Db.new
        verbose("List","Initialize")
        $opt||=GetOpts.new
      end

      # id = "layer:site"
      def get(id)
        add_all(id) unless @data.key?(id)
        super
      end

      def site(id=nil)
        get("#{@layer}:#{id}")
      end

      def exe(args,src='local') # As a individual cui command
        site(args.shift).exe(args,src)
      end

      def server(sary)
        sary.each{|sid|
          sleep 0.3
          site(sid)
        }.empty? && site
        sleep
      rescue InvalidID
        $opt.usage('(opt) [id] ....')
      end

      def ext_shell
        extend(Shell)
      end

      private
      # generate all layer of the site
      def add_all(id)
        layer,sid=id.split(':')
        unless @site_cfgs.key?(sid)
          cfg=@site_cfgs[sid]=Config.new("site_#{sid}",@cfg)
          cfg.update('id' => sid,:site_db =>@db.set(sid),:site_stat => Prompt.new)
          $layers.each{|key,mod|
            oid="#{key}:#{sid}"
            add(oid,mod,cfg) unless @data.key?(oid)
          }
        end
        self
      end

      def add(id,mod,cfg)
        set(id,mod.new(cfg))
        @data[id]
      end
    end

    module Shell
      require "libsh"
      def self.extended(obj)
        Msg.type?(obj,List)
      end

      def shell(sid)
        id="#{@layer}:#{sid}"
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
      def add(id,mod,cfg)
        exe=super
        # Add jump groups
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

      def get_site(ent)
        ldb=ent.cfg[:site_db]
        ldb["#{ent.id}_site"]||ldb['app_site']
      end

      def cap(type)
        {'caption'=>"Switch #{type}s",'color'=>5,'column'=>2 }
      end

      def layer_list
        h={}
        $layers.values.each{|mod|
          str=mod.to_s.split(':').last
          h[str.downcase]="#{str} layer"
        }
        h
      end

      class Jump < LongJump; end
    end
  end
end
