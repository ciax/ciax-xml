#!/usr/bin/ruby
class Label < Hash
  def initialize(hash)
    self['id'] = 'OBJECT'
    self['time'] = 'TIMESTAMP'
    update(hash)
  end

  def convert(stat)
    result={}
    stat.each{|k,v|
      case k
      when 'header'
        result[k]=v
      else
        next unless key?(k)
        v['label']=self[k]
      end
      result[k]=v
    }
    result
  end
end
