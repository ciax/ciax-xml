#!/usr/bin/ruby
require 'libinteract'
require 'libfield'
module Frm
  class Int < Interact
    attr_reader :field
    def initialize(fdb)
      Msg.type?(fdb,Frm::Db)
      super(Command.new(fdb[:cmdframe]))
      @prompt['id']=fdb['id']
      @port=fdb['port'].to_i-1000
      @field=Field.new
    end

    def exe(cmd)
      super
    rescue
      cl=Msg::CmdList.new("Internal Command",2)
      cl['set']="Set Value [key(:idx)] (val)"
      cl['unset']="Remove Value [key]"
      cl['save']="Save Field [key,key...] (tag)"
      cl['load']="Load Field (tag)"
      cl['sleep']="Sleep [n] sec"
      cl.error
    end

    def to_s
      @field.to_s
    end
  end
end
