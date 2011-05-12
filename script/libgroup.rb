#!/usr/bin/ruby
class Group < Hash
  def initialize(hash)
    self['id'] = '0'
    self['time'] = '0'
    update(hash)
  end

  def convert(stat)
    result={'header' => stat['header']}
    each{|k,v|
      next unless stat.key?(k)
      result[k]=stat[k].dup
      result[k]['group']=v
    }
    result
  end
end
