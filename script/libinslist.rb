#!/usr/bin/ruby
require "liblocdb"
require "libfrmsh"
require "libappsh"
require "libhexsh"

module Ins
  class List < Hash
    def initialize(id)
      @id=id
      fl=self['frm']=Frm::List.new(id)
      al=self['app']=App::List.new(fl)
      shdom=fl.shdom=al.shdom
      grp=shdom.add_group('lay',"Change Layer")
      grp.update_items({'frm'=>"Frm mode",'app'=>"App mode"})
      grp.reset_proc{|item|
        raise(TransLayer,item.id)
      }

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
