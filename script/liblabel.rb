#!/usr/bin/ruby
class Label < Hash
  def initialize(hash)
    raise "Label have to be given Db" unless hash.kind_of?(Db)
    self['time'] = 'TIMESTAMP'
    self['class'] = 'CLASS ID'
    self['frame'] = 'FLAME ID'
    update(hash.status[:label]||{})
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
