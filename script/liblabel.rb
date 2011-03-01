#!/usr/bin/ruby
require "librepeat"

class Label
  attr_reader :label
  def initialize(db,domain,key,xpath=nil)
    @label={}
    if xpath
      db.find_each(domain,xpath){|e|
        sym=e['label'] || next
        @label[e[key]]={'label'=>sym}
        @label[e[key]]['group']=e['group'] if e['group']
      }
    else
      rep=Repeat.new
      rep.each(db[domain]){|e|
        sym=e['label'] || next
        @label[rep.subst(e[key])]={'label'=>rep.subst(sym)}
      }
    end
  end

  def merge(stat)
    @label.each{|id,label|
      case stat[id]
      when Hash
        stat[id].update(@label[id])
      else
        val=stat[id]
        stat[id]=@label[id]
        stat[id]['val']=val
      end
    }
    stat
  end
end
