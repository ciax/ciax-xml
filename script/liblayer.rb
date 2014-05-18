#!/usr/bin/ruby
require "libmsg"
require "libcommand"

module CIAX
  module Layer
    # Layer List
    class List < Hashx
      def initialize(cfg=Config.new)
        @cfg=type?(cfg,Config)
        @ljgrp=JumpGrp.new
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
          self[layer][site].shell
        rescue SiteJump
          site=$!.to_s
          retry
        rescue LayerJump
          layer=$!.to_s
          retry
        end
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end

    class JumpGrp < Group
      def initialize(upper=Config.new,crnt={})
        super
        @cfg['caption']='Switch Layer'
        @cfg['color']=5
        @cfg['column']=5
        set_proc{|ent| raise(LayerJump,ent.id) }
      end
    end
  end
end
