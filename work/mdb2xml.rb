#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias m2x
require 'json'
OPETBL = { '=~' => 'match', '!=' => 'not', '==' => 'equal', '!~' => 'unmatch' }
def mktag(tag, atrb)
  printf('  ' * @indent + '<%s', tag)
  atrb.each do|k, v|
    printf(' %s="%s"', k, v)
  end
end

# single line element
def indent(tag, atrb = {}, text = nil)
  mktag(tag, atrb)
  if text
    printf(">%s</%s>", text, tag)
    puts
  else
    puts '/>'
  end
end

def topen(tag, atrb = {})
  mktag(tag, atrb)
  puts '>'
  @indent += 1
end

def tclose(tag)
  @indent -= 1
  printf('  ' * @indent + "</%s>", tag)
  puts
end

def enclose(tag, atrb = {}, enum = nil)
  return if enum && enum.empty?
  topen(tag, atrb)
  if enum
    enum.each{ |a| yield a}
  else
    yield
  end
  tclose(tag)
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
  ary.each do|e|
    case e
    when Array
      if e[0].to_s == 'mcr'
        indent(e[0], name: e[1])
      else
        indent(e.shift, a2h(e, :site, :name, :skip))
      end
    else
      tag_wait(e)
    end
  end
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
  atrb = {id: uid, label: @ucap[uid]}
  enclose(:unit, atrb, @umem[uid]) do |id|
    tag_item(id)
  end
end

def tag_group(gid, gary)
atrb = {id: gid, caption: @gcap[gid]}
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
@ucap = @mdb.delete('caption_unit') || {}
@gcap = @mdb.delete('caption_group') || {}
@umem = @mdb.delete('member_unit') || {}
@gmem = @mdb.delete('member_group') || {}

@indent = 0
puts '<?xml version="1.0" encoding="utf-8"?>'
puts enclose(:mdb, xmlns: 'http://ciax.sum.naoj.org/ciax-xml/mdb') {
  label = "#{@mcap.upcase} Macro"
  atrb = { id: @mcap, version: '1', label: label, port: '55555'}
  enclose(:macro, atrb, @gmem) do |gid, mem|
    tag_group(gid, mem)
  end
}
