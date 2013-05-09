#!/usr/bin/ruby
require "liblocdb"
require "libfrmsh"
require "libappsh"
require "libhexsh"

module Ins
  module Layer
    def newsh(id)
      switch_layer(super,'lay',"Change Layer",{'frm'=>"Frm mode",'app'=>"App mode"})
    end
  end

  class List < Hash
    def initialize(id)
      @id=id
      fl=self['frm']=Frm::List.new(id).extend(Layer)
      self['app']=App::List.new(fl).extend(Layer)
    end

    def shell
      lyr='app'
      begin
        li=self[lyr]
        li.id=@id
        li.shell
      rescue TransLayer
        lyr=$!.to_s
        @id=li.id
        retry
      end
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('et')
  puts Ins::List.new(ARGV.shift).shell
end
