#!/usr/bin/ruby
require "libdatax"
require "liblocal"

module CIAX
  # This is parent of Layer List, Site List.
  # @cfg should have [:jump_groups]
  # attr should have [:jump_class] (Used in Local::Jump::Group)
  class List < DataH
    attr_reader :cfg,:jumpgrp
    # level can be Layer or Site
    def initialize(cfg,attr={})
      @cfg=cfg.gen(self).update(attr)
      type?(@cfg[:jump_groups],Array)
      @jumpcls=type?(@cfg[:jump_class],Module)
      name=m2id(@jumpcls,-2)
      super(name,{},@cfg[:dataname]||'list')
      @jumpgrp=Local::Jump::Group.new(@cfg)
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
      rescue @jump_cls
        key,par=$!.to_s.split(':')
        retry
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
