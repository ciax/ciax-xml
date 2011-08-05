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
    view['list'].each{|id,hash|
      hash['label']=self[id]
    }
    self
  end
end
