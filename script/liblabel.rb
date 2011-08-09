#!/usr/bin/ruby
class Label < Hash
  def initialize(hash)
    raise "Label have to be given Db" unless hash.kind_of?(Db)
    update(hash.status[:label]||{})
  end

  def convert(view)
    view['label']=Hash[self]
    self
  end
end
