#!/usr/bin/ruby
class Group < Hash
  def initialize(hash)
    self['id'] = '0'
    self['time'] = '0'
    update(hash||{})
  end
end
