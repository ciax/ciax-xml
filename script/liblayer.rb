#!/usr/bin/ruby
require "libmsg"
require "libcommand"
require "libsitedb"

module CIAX
  module Layer
    # Layer List
    class List < Hashx
      def initialize(upper=nil)
        @cfg=Config.new('layer',upper)
        @ljgrp=JumpGrp.new(@cfg)
        @cfg[:ldb]||=Site::Db.new
      end

      def add_layer(layer)
        type?(layer,Module)
        str=layer.to_s.split(':').last
        id=str.downcase
        key="#{id}_list".to_sym
        lst=(@cfg[key]||=layer::List.new(@cfg))
        @ljgrp.add_item(id,str+" mode")
        lst.init_procs << proc{|exe| exe.cobj.lodom.join_group(@ljgrp) }
        self[id]=lst
      end

      def shell(site)
        layer=keys.last
        begin
          self[layer].shell(site)
        rescue LayerJump
          layer,site=$!.to_s.split(':')
          retry
        end
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end

    class JumpGrp < Group
      def initialize(upper=nil,crnt={})
        super
        @cfg['caption']='Switch Layer'
        @cfg['color']=5
        @cfg['column']=5
        set_proc{|ent|
          site=ent.cfg[:ldb]['id']
          raise(LayerJump,"#{ent.id}:#{site}")
        }
      end
    end
  end
end
