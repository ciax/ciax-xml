#!/usr/bin/ruby
require "libcircular"
require "librepeat"
class ClsView
  attr_reader :tbl

  def initialize(ddb)
    @tbl={}
    @c=Circular.new(2)
    plabel=''
    @rep=Repeat.new
    ddb['status'].each{|e1|
      case e1.name
      when 'value'
        label=e1['label'].split(' ').last
        if label != plabel
          @c.reset
          plabel=label
        end
        set_tbl(e1)
      when 'repeat'
        @rep.repeat(e1){
          @c.reset
          e1.each{|e2|
            set_tbl(e2)
            @c.next
          }
        }
      end
    }
  end
  
  def set_tbl(e)
    id=@rep.subst(e['id'])
    label=@rep.subst(e['label'])
    @tbl[id]={:label=>label,:symbol=>e['symbol'],:group=>@c.times }
  end

end
