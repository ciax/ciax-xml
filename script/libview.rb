#!/usr/bin/ruby
# Status to View (String with attributes)
class View < Hash
  def initialize(ids)
    hash=self['list']={}
    ids.each{|id|
      case id
      when 'id','frame','class'
        self[id]=''
      else
        hash[id]={'val'=>''}
      end
    }
  end

  def upd(stat)
    each{|k,v|
      case v
      when Hash
        self[k].each{|i,h|
          h['val']=stat[i]
        }
      else
        self[k]=stat[k]
      end
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
