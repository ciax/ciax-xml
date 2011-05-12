#!/usr/bin/ruby
class Label < Hash
  def initialize(hash)
    self['id'] = 'OBJECT'
    self['time'] = 'TIMESTAMP'
    update(hash)
  end
end
