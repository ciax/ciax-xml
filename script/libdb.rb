#!/usr/bin/ruby
require "libverbose"
class Db < Hash

  def to_s
    Verbose.view_struct(self)
  end

  def cover(hash) # override with hash
    Db[rec_merge(self,hash)]
  end

  private
  def rec_merge(me,oth)
    me.merge(oth){|k,s,h|
      Hash === h ? rec_merge(s,h) : s
    }
  end
end
