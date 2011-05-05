#!/usr/bin/ruby
require "librepeat"

class Label < Hash
  def initialize
    self['id'] = {'label' => 'OBJECT','group' => '0'}
    self['time'] = {'label' => 'TIMESTAMP','group' => '0' }
  end

  def convert(stat)
    result={}
    stat.each{|k,v|
      case k
      when 'header'
        result[k]=v
      else
        next unless key?(k)
        v.update(self[k])
      end
      result[k]=v
    }
    result
  end
end
