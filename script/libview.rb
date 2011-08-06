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
    self['list'].each{|k,h|
      h['val']=stat[k]
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
        list << "#{k}:"
        pick=ENV['VAL']||'.'
        exp=pick.tr(':','|')
        v.each{|i,h|
          next unless /#{exp}/ === i
          list << "  #{i} : #{h}"
        }
      when Array
        list << "#{k}:"
        v.each{|l|
          list << "  #{l}"
        }
      else
        list << "#{k} : #{v}"
      end
    }
    list.join("\n")
  end
end
