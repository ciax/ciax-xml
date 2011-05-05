#!/usr/bin/ruby
# String to Qualified string (String with attributes)
module S2q
  def s2q(stat)
    return stat.clone if stat.key?('header')
    result={'header' => {}}
    ['id','class','frame'].each{|key|
      result['header'][key]=stat[key] if stat.key?(key)
    }
    stat.each{|k,v|
      result[k]={'val'=>v}
    }
    result
  end
end
