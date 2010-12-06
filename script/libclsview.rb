#!/usr/bin/ruby
require "librepeat"
class ClsView
  attr_reader :tbl

  def initialize(ddb)
    @tbl={}
    @group='0'
    flip=false
    plabel=''
    @rep=Repeat.new
    ddb['status'].each{|e1|
      case e1.name
      when 'value'
        label=e1['label'].split(' ').last
        if label != plabel
          flip=!flip
          if flip
            @group.next!
          end
          plabel=label
        else
          flip=false
        end
        set_tbl(e1)
      when 'repeat'
        @rep.repeat(e1){
          @group.next!
          e1.each{|e2|
            set_tbl(e2)
          }
        }
      end
    }
  end
  
  def set_tbl(e)
    id=@rep.subst(e['id'])
    label=@rep.subst(e['label'])
    @tbl[id]={:label=>label,:symbol=>e['symbol'],:group=>@group.dup }
  end

end
