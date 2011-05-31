#!/usr/bin/ruby
class Group < Hash
  def initialize(hash)
    self['id'] = '0'
    self['time'] = '0'
    update(hash||{})
  end

  def convert(view)
    list=[]
    view['list'].each{|hash|
      id=hash['id']
      next unless key?(id)
      hash['group']=self[id]
      list << hash
    }
    view['list']=list
    self
  end
end
