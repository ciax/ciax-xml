#!/usr/bin/ruby
require "libcircular"
require "librepeat"
class ClsView
  attr_reader :tbl

  def initialize(ddb)
    @tbl={}
    @c=Circular.new(2)
    @plabel=[]
    @rep=Repeat.new
    ddb['status'].each{|e1|
      case e1.name
      when 'value'
        set_tbl(e1)
      when 'repeat'
        @rep.repeat(e1){
          e1.each{|e2|
            set_tbl(e2)
          }
        }
      end
    }
  end

  def set_tbl(e)
    label=e['label'].split(' ')
    if label.first != @plabel.first && label.last != @plabel.last
      @c.reset
      @plabel=label
    else
      @c.next
    end
    id=@rep.subst(e['id'])
    label=@rep.subst(e['label'])
    @tbl[id]={:label=>label,:symbol=>e['symbol'],:group=>@c.times }
  end

end
