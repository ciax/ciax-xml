#!/usr/bin/ruby
module S2h
  def s2h(stat)
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
