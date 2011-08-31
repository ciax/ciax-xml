#!/usr/bin/ruby
require "libverbose"
class Db < Hash
  def to_s
    Verbose.view_struct(self)
  end

  def >>(hash) # overwrite hash
    replace(rec_merge(hash,self))
  end

  def <<(hash) # overwritten by hash
    replace(rec_merge(self,hash))
  end

  private
  def rec_merge(i,o)
    i.merge(o){|k,a,b|
      Hash === b ? rec_merge(a,b) : b
    }
  end
end
