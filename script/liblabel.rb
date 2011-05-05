#!/usr/bin/ruby
require "librepeat"

class Label
  attr_reader :label
  def initialize(doc,domain,key,xpath=nil)
    @label={}
    @label['id'] = {'label' => 'OBJECT','group' => '0'}
    @label['time'] = {'label' => 'TIMESTAMP','group' => '0' }
    if xpath
      doc.find_each(domain,xpath){|e|
        sym=e['label'] || next
        id=e[key] || next
        @label[id]={'label'=>sym}
        @label[id]['group']=e['group'] if e['group']
      }
    else
      rep=Repeat.new
      rep.each(doc[domain]){|e|
        sym=e['label'] || next
        id=rep.format(e[key])
        @label[id]={'label'=>rep.format(sym)}
        @label[id]['group']=rep.format(e['group']) if e['group']
      }
    end
  end

  def merge(stat)
    result={}
    stat.each{|k,v|
      case k
      when 'header'
        result[k]=v
      else
        next unless @label.key?(k)
        v.update(@label[k])
      end
      result[k]=v
    }
    result
  end
end
