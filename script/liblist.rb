#!/usr/bin/ruby
require "libdatax"

module CIAX
  class List < DataH
    attr_reader :jumpgrp
    def initialize(level,inter_cfg={},attr={})
      @level=type?(level,Module)
      name=level.to_s.split(':').last.downcase
      @cfg=Config.new("list_#{name}",inter_cfg).update(attr)
      super(name,{},@cfg[:dataname]||'list')
      @cfg[:jump_groups]||=[]
      attr={'caption'=>"Switch #{name.capitalize}s",'color'=>5,'column'=>3}
      @jumpgrp=Group.new(@cfg,attr)
      @jumpgrp.cfg.proc{|ent|
        raise(@level::Jump,ent.id)
      }
      $opt||=GetOpts.new
    end

    def shell(key=nil,par=nil)
      begin
        if lst=get(key)
          lst.shell(par)
        else
          get(keys.first).shell(key)
        end
      rescue @level::Jump
        key,par=$!.to_s.split(':')
        retry
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
