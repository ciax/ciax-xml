#!/usr/bin/ruby
# Status to View (String with attributes)
class View < Hash
  def initialize(stat={})
    if stat.key?('list')
      update(stat)
    else
      ary=self['list']=[]
      stat.each{|k,v|
        case k
        when 'id','frame','class'
          self[k]=v
        end
        ary << {'id'=>k, 'val'=>v}
      }
    end
  end

  def to_s
    header=[]
    ['id','frame','class'].each{|s|
      header << "#{s} = #{self[s]}" if key?(s)
    }
    (header+self['list']).join("\n")
  end

  def convert(key,db)
    list=[]
    self['list'].each{|hash|
      id=hash['id']
      next unless db.key?(id)
      hash[key]=db[id]
      list << hash
    }
    self['list']=list
    self
  end
end
