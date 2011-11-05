#!/usr/bin/ruby
module ModXml
  # Common with LIBXML,REXML
  def to_s
    @e.to_s
  end

  def [](key)
    @e.attributes[key]
  end

  def name
    @e.name
  end

  def map
    ary=[]
    each{|e|
      ary << (yield e)
    }
    ary
  end

  def attr2db(db,id='id')
    # <xml id='id' a='1' b='2'> => db[:a][id]='1', db[:b][id]='2'
    raise "Param should be Hash" unless Hash === db
    attr={}
    to_h.each{|k,v|
      if defined?(yield) && k != 'format'
        attr[k] = yield v
      else
        attr[k] = v
      end
    }
    key=attr.delete(id) || return
    attr.each{|str,v|
      sym=str.to_sym
      db[sym]={} unless db.key?(sym)
      db[sym][key]=v
      @v.msg{"ATTRDB:"+str.upcase+":[#{key}] : #{v}"}
    }
    key
  end
end
