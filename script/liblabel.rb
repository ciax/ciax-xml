#!/usr/bin/ruby
class Label < Hash
  def initialize(hash)
    self['time'] = 'TIMESTAMP'
    update(hash||{})
  end

  def convert(view)
    list=[]
    view['list'].each{|hash|
      id=hash['id']
      next unless key?(id)
      hash['label']=self[id]
      list << hash
    }
    view['list']=list
    self
  end
end
