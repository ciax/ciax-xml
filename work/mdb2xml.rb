#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias m2x
require 'json'
OPETBL = { '=~' => 'match', '!=' => 'not', '==' => 'equal', '!~' => 'unmatch' }
def mktag(tag, atrb)
  str = format('  ' * @indent + '<%s', tag)
  atrb.each do|k, v|
    str << format(' %s="%s"', k, v)
  end
  str
end

# single line element
def indent(tag, atrb = {}, text = nil)
  str = mktag(tag, atrb)
  if text
    str << format(">%s</%s>", text, tag)
  else
    str << '/>'
  end
  str
end

def enclose(tag, atrb = {}, enum = nil)
  @indent += 1
  if enum
    ary = enum.map{ |a| yield a}.compact
  else
    ary = [yield].compact
  end
  @indent -= 1
  return if ary.empty?
  ary.unshift(mktag(tag, atrb)+'>')
  ary << format('  ' * @indent + "</%s>", tag)
  ary.join("\n")
end

def a2h(vals, *tags)
  atrb = {}
  vals.each do|val|
    atrb[tags.shift] = val
  end
  atrb
end

def hpick(hash, *tags)
  res = {}
  tags.each { |k| res[k] = hash[k.to_s] }
  res
end

def prt_cond(cond, form = 'msg')
  atrb = a2h(cond, :site, :var, :ope, :cri, :skip)
  atrb[:form] = form
  ope = OPETBL[atrb.delete(:ope)]
  cri = atrb.delete(:cri)
  indent(ope, atrb, cri)
end

def tag_wait(e)
  if e['sleep']
    indent(:wait, hpick(e, :sleep, :label))
  else
    enclose(:wait, hpick(e, :retry, :label), e['until']) do |cond|
      prt_cond(cond, 'data')
    end
  end
end

def tag_seq(ary)
  ary.map do|e|
    case e
    when Array
      # Don't use e.shift which will affect following process
      cmd,*args = e
      if cmd.to_s == 'mcr'
        indent(cmd, a2h(args, :name))
      else
        indent(cmd, a2h(args, :site, :name, :skip))
      end
    else
      tag_wait(e)
    end
  end.join("\n")
end

def tag_select(ary)
  atrb = { site: ary['site'], var: ary['var'], form: 'msg' }
  enclose(:select, atrb, ary['option']) do|val, mcr|
    enclose(:option, val: val) do
      indent(:mcr, name: mcr)
    end
  end
end

def tag_item(id)
  db = @mdb['index'][id]
  return unless db
  return if @index.include?(id)
  @index << id
  atrb = { id: id }
  atrb[:label] = db['label'] if db['label']
  enclose(:item, atrb, db) do|key, ary|
    case key
    when 'goal','check'
      enclose(key, {}, ary) do |cond|
        prt_cond(cond)
      end
    when 'seq'
      tag_seq(ary)
    when 'select'
      tag_select(ary)
    end
  end
end

def tag_unit(uid)
  uat=@unit[uid]
  atrb = {id: uid, title: uat['title'], label: uat['caption']}
  enclose(:unit, atrb, uat['member']) do |id|
    tag_item(id)
  end
end

def tag_group(gid, gary)
  atrb = {id: gid, caption: @group[gid]['caption']}
  enclose(:group, atrb, gary) do|uid|
    if /unit_/ =~ uid
      tag_unit(uid)
    else
      tag_item(uid)
    end
  end
end

abort 'Usage: mdb2xml [mdb(json) file]' if STDIN.tty? && ARGV.size < 1

@mdb = JSON.load(gets(nil))
@mcap = @mdb.delete('caption_macro') || 'ciax'
@group = @mdb.delete('group') || {}
@unit = @mdb.delete('unit') || {}
@index = []
@indent = 0
puts '<?xml version="1.0" encoding="utf-8"?>'
puts enclose(:mdb, xmlns: 'http://ciax.sum.naoj.org/ciax-xml/mdb') {
  label = "#{@mcap.upcase} Macro"
  atrb = { id: @mcap, version: '1', label: label, port: '55555'}
  enclose(:macro, atrb, @group) do |gid, at|
    tag_group(gid, at['member'])
  end
}
