#!/usr/bin/ruby
require "libdatax"

module CIAX
  class List < DataH
    def initialize(level,upper=nil)
      @level=type?(level,Module)
      name=level.to_s.split(':').last.downcase
      @cfg=Config.new("#{name}_list",upper)
      super(name,{},@cfg[:dataname]||'list')
      @cfg[:jump_groups]||=[]
      attr={'caption'=>"Switch #{name}s",'color'=>5,'column'=>2}
      @jumpgrp=Group.new(@cfg,attr).set_proc{|ent|
        raise(@level::Jump,ent.id)
      }
      $opt||=GetOpts.new
    end

    def shell(key=nil,par=nil)
      begin
        (get(key)||lastval).shell(par)
      rescue @level::Jump
        key,par=$!.to_s.split(':')
        retry
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
