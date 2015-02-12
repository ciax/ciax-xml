#!/usr/bin/ruby
require "libdatax"
require "libsitedb"

module CIAX
  module Site
    # Site List
    class List < DataH
      # shdom: Domain for Shared Command Groups
      def initialize(upper=nil)
        @cfg=Config.new("list_site",upper)
        super('site',{},@cfg[:dataname]||'list')
        @cfg[:site_list]=self
        @site_cfgs={}
        @db=Db.new
        verbose("List","Initialize")
        $opt||=GetOpts.new
      end

      def exe(args) # As a individual cui command
        get(args.shift).exe(args,'local')
      end

      # id = "layer:site"
      def get(id)
        add(id) unless @data.key?(id)
        super
      end

      def shell(id)
        begin
          get(id).shell
        rescue Jump
          id=$!.to_s
          retry
        rescue InvalidID
          $opt.usage('(opt) [id]')
        end
      end

      def server(ary)
        ary.each{|i|
          sleep 0.3
          get(i)
        }.empty? && get(nil)
        sleep
      rescue InvalidID
        $opt.usage('(opt) [id] ....')
      end

      private
      def mk_jump_group(exe)
        jg=exe.cfg[:jump_groups]||=[]
        attr={'caption'=>"Switch sites",'color'=>5,'column'=>2}
        jg << Group.new(exe.cfg,attr).set_proc{|ent|
          id="#{ent.layer}:#{ent.id}"
          raise(Jump,id)
        }.update_items(@db.list)
        attr={'caption'=>"Switch layer",'color'=>5,'column'=>2}
        jg << Group.new(exe.cfg,attr).set_proc{|ent|
          id="#{ent.id}:#{get_site(ent)}"
          raise(Jump,id)
        }.update_items(layer_list)
        # JumpGroup is set to Domain
        jg.each{|grp|
          exe.cobj.lodom.join_group(grp)
        }
      end

      def add(id)
        layer,site=id.split(':')
        site_cfg=(@site_cfgs[site]||=Config.new("site_#{site}",@cfg).update('id' => site,:ldb =>@db.set(site),:site_stat => Prompt.new))
        exe=$layers[layer].new(site_cfg)
        mk_jump_group(exe)
        set(id,exe)
      end

      def get_site(ent)
        ldb=ent.cfg[:ldb]
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

    class Jump < LongJump; end

    if __FILE__ == $0
      require "libhexexe"
      require "libwatexe"
      require "libfrmexe"
      require "libappexe"
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        puts List.new.shell("wat:#{ARGV.shift}")
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
