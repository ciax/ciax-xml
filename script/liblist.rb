#!/usr/bin/ruby
require "libdatax"
require "liblocal"

module CIAX
  # This is parent of Layer List, Site List.
  # @cfg should have [:jump_groups]
  class List < DataH
    attr_reader :jumpgrp
    # level can be Layer or Site
    def initialize(level,cfg,attr={})
      @level=type?(level,Module)
      @cfg=cfg.gen(self).update(attr)
      name=level.to_s.split(':').last.downcase
      super(name,{},@cfg[:dataname]||'list')
      @jumpgrp=Local::Jump::Group.new(@cfg,{:level => @level})
      @cfg[:jump_groups]+=[@jumpgrp]
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
