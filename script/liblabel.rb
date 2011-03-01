#!/usr/bin/ruby
require "librepeat"

class Label
  attr_reader :label
  def initialize(db,domain,xpath=nil)
    @label={}
    if xpath
      db.find_each(domain,xpath){|e|
        sym=e['label'] || next
        @label[e['assign']]=sym
      }
    else
      rep=Repeat.new
      rep.each(db[domain]){|e|
        sym=e['label'] || next
        @label[rep.subst(e['id'])]=rep.subst(sym)
      }
    end
  end

  def merge(stat)
    @label.each{|id,label|
      case stat[id]
      when Hash
        stat[id]['label']=@label[id]
      else
        stat[id]={'label'=>@label[id],'val'=>stat[id]}
      end
    }
    stat
  end
end
