#!/usr/bin/ruby
require "libsitedb"
require "libwatexe"
require "libfrmexe"
require "libappexe"

module CIAX
  module Site
    # Site List
    class List < DataH
      # shdom: Domain for Shared Command Groups
      def initialize(upper=nil)
        @cfg=Config.new("list_site",upper)
        super('site',{},@cfg[:dataname]||'list')
        @cfg[:site_list]=self
        @cfg[:jump_groups]||=[]
        @cfg[:current_site]||=''
        @cfg[:current_layer]||=''
        @db=Db.new
        attr={'caption'=>"Switch sites",'color'=>5,'column'=>2}
        @cfg[:jump_groups] << Group.new(@cfg,attr).set_proc{|ent|
          id="#{@cfg[:current_layer]}:#{ent.id}"
          warn "Jump to #{id}"
          raise(Jump,id)
        }.update_items(@db.list)
        attr={'caption'=>"Switch layer",'color'=>5,'column'=>2}
        @cfg[:jump_groups] << Group.new(@cfg,attr).set_proc{|ent|
          id="#{ent.id}:#{@cfg[:current_site]}"
          warn "Jump to #{id}"
          raise(Jump,id)
        }.update_items({'frm' => "Frame layer",'app' => "App layer",'wat' => "Watch layer"})
        #
        verbose("List","Initialize")
        $opt||=GetOpts.new
      end

      def exe(args) # As a individual cui command
        get(args.shift).exe(args,'local')
      end

      # id = "layer:site"
      def get(id)
        add(id) unless @data.key?(id)
        layer,site=id.split(':')
        @cfg[:current_site].replace(site)
        @cfg[:current_layer].replace(layer)
        super(id)
      end

      def set(id,exe)
        type?(exe,Exe)
        return self if @data.key?(id)
        # JumpGroup is set to Domain
        @cfg[:jump_groups].each{|grp|
          exe.cobj.lodom.join_group(grp)
        }
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
      def add(id)
        layer,site=id.split(':')
        site_cfg=Config.new("site_#{site}",@cfg).update('id' => site,:ldb =>@db.set(site))
        lm=layer.capitalize
        set(id,eval("#{lm}.new(site_cfg)"))
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
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
