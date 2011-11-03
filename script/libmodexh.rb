#!/usr/bin/ruby
require 'libmsg'
require 'json'
module ModExh
  # module which includes this should be Hash
  def to_s
    Msg.view_struct(self)
  end

  def to_j
    JSON.dump(Hash[self])
  end

  def update_j(str)
    if str && !str.empty?
      deep_update(JSON.load(str))
    else
      warn "No status at ModExH::update_j()"
    end
    self
  end

  def deep_update(hash)
    rec_merge(hash,self)
    self
  end

  private
  def rec_merge(a,b)
    case a
    when Hash
      b= b.is_a?(Hash) ? b : {}
      a.keys.each{|i| b[i]=rec_merge(a[i],b[i])}
    when Array
      b= b.is_a?(Array) ? b : []
      a.size.times{|i| b[i]=rec_merge(a[i],b[i])}
    else
      b=a||b
    end
    b
  end

end
