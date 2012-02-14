#!/usr/bin/ruby
require "libmsg"
require "json"
require "libexenum"

class Update < Array
  def upd
    each{|p| p.call }
    self
  end
end

class IoFile < ExHash
  attr_reader :updlist
  def initialize(type,id=nil,host=nil)
    @v=Msg::Ver.new(type,6)
    if id
      base="/json/#{type}_#{id}"
      if host
        require "open-uri"
        @base="http://"+host+base
        @type='url'
      else
        @base=VarDir+base
        @type='file'
      end
      self['id']=id
      @fname=@base+'.json'
    end
    @updlist=Update.new
  end

  def settag(tag)
    @fname=@base+"_#{tag}.json" if @base
  end

  def load
    case @type
    when 'file'
      if File.exist?(@fname)
        load_uri(@fname)
      else
        Msg.warn("  -- no json file (#{@fname})")
      end
    when 'url'
      load_uri(@fname)
    else
      deep_update(JSON.load(gets(nil)))
    end
    @updlist.upd
    self
  end

  def save(data=nil)
    case @type
    when 'file'
      @v.msg{"Saving #{self['id']} file"}
      open(@fname,'w'){|f| f << JSON.dump(data||to_hash)}
    else
      puts JSON.dump(data||to_hash)
    end
    self
  end

  def to_j
    JSON.dump(to_hash)
  end

  private
  def load_uri(uri)
    @v.msg{"Loading URL #{uri}"}
    open(uri){|f|
      str=f.read
      if str.empty?
        Msg.warn(" -- json file is empty")
      else
        deep_update(JSON.load(str))
      end
    }
  end
end
