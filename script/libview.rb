#!/usr/bin/ruby
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

  def upd(stat)
    self['list'].each{|k,v|
      v['val']=stat[k]
    }
    self
  end

  # Filterling values by env value of VAL
  # VAL=a:b:c -> grep "a|b|c"
  def to_s
    list=[]
    each{|k,v|
      case v
      when Hash
        list << "#{k.inspect}:"
        pick=ENV['VAL']||'.'
        exp=pick.tr(':','|')
        v.each{|i,h|
          next unless /#{exp}/ === i
          list << "  #{i.inspect} : #{h}"
        }
      when Array
        list << "#{k.inspect}:"
        v.each{|l|
          list << "  #{l}"
        }
      else
        list << "#{k.inspect} : #{v}"
      end
    }
    list.join("\n")
  end
end
