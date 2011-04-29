#!/usr/bin/ruby
require "librepeat"

class Label
  attr_reader :label
  def initialize(db,domain,key,xpath=nil)
    @label={'id' => {'label' => 'OBJECT','group' => '0'},
      'time' => {'label' => 'TIMESTAMP','group' => '0' }}
    if xpath
      db.find_each(domain,xpath){|e|
        sym=e['label'] || next
        id=e[key] || next
        @label[id]={'label'=>sym}
        @label[id]['group']=e['group'] if e['group']
      }
    else
      rep=Repeat.new
      rep.each(db[domain]){|e|
        sym=e['label'] || next
        id=rep.format(e[key])
        @label[id]={'label'=>rep.format(sym)}
        @label[id]['group']=rep.format(e['group']) if e['group']
      }
    end
  end

  def merge(stat)
    result={}
    @label.each{|id,label|
      case stat[id]
      when Hash
        result[id]=stat[id].update(@label[id])
      when nil
      else
        val=stat[id]
        result[id]=@label[id]
        result[id]['val']=val
      end
    }
    result
  end
end
