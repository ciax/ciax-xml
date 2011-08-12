#!/usr/bin/ruby
require "libverbose"
# Status to View (String with attributes)
class View < Hash
  def initialize(stat)
    @stat=stat
    hash=self['list']={}
    stat.each{|k,v|
      case k
      when 'id','frame','class'
        self[k]=v
      else
        hash[k]={'val'=>v}
      end
    }
  end

  def upd
    self['list'].each{|k,v|
      v['val']=@stat[k]
    }
    self
  end

  def to_s
    Verbose.view_struct(self)
  end
end
