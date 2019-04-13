#!/usr/bin/env ruby
# IDB,CDB CSV(CIAX-v1) to MDB
# alias c2m
require 'optparse'
require 'json'

OPETBL = { '~' => '=~', '!' => '!=', '=' => '==', '^' => '!~' }.freeze

######### Shared Methods ##########

def get_site(elem)
  @skip = nil
  elem.split(':').map do |e|
    if /^!/ =~ e
      @skip = 'true'
      var = $'
    else
      var = e
    end
    var
  end
end

def mk_cond(site, cond)
  case cond
  when /[~!=^]+/
    ary = [site, $`, OPETBL[$&[0]], $']
    ary << @skip if @skip
    ary
  when '*', '', nil
    nil
  else
    abort "IDB: NO operator in #{cond}"
  end
end

def sep_cond(line)
  line.split('&').map do |s|
    site, cond = yield s
    mk_cond(site, cond)
  end.compact
end

def _gid
  'grp_' + @gcore
end

def _uid
  'unit_' + @ucore
end

# Add index to group
def _add_i2g(gid, iid)
  ary = @group[gid][:member] ||= []
  ary << iid unless ary.include?(iid)
  ary
end

# Add unit to group
def _add_u2g(gid, uid)
  ary = @group[gid][:units] ||= []
  ary << uid unless ary.include?(uid)
  ary
end

# Add index to unit
def _add_i2u(uid, iid)
  ary = @unit[uid][:member] ||= []
  ary << iid unless ary.include?(iid)
  ary
end

# Group is enclosed by starting !?,----- Title ----- to next title
def grouping(id, label, inv, name)
  if /^!/ =~ id
    @gcore = "#{name}_#{$'}"
    @group[_gid] = { caption: label.gsub(/ *-{2,} */, ''), rank: inv.to_i }
    return
  elsif !@gcore # default group
    @gcore = name
    @group[_gid] = { caption: "#{name.upcase} Group", rank: inv.to_i }
  end
  id
end

# Unit is enclosed by ???, Title,,cap
#  and member should be invisible
def unitting(id, label, inv, type)
  if type == 'cap'
    @ucore = @gcore + '_' + id.tr('^_a-zA-Z0-9', '')
    @unit[_uid] = { title: id, label: label }
    _add_u2g(_gid, _uid)
    return
  elsif !inv || inv.empty?
    @ucore = nil
  end
  id
end

def iteming(id, label, index)
  if @ucore
    _add_i2u(_uid, id)
  else
    _add_i2g(_gid, id)
  end
  item = (index[id] ||= {})
  item['label'] = label
  item
end

# convert flag of ignore
def ignore_flg(args)
  return unless /^!/ =~ args[0]
  args[0] = $'
  args << true
end

# convert cfg or upd or exec
def conv_type(args)
  return if %w(mcr system).include?(args[0])
  conv_exec_type(args)
end

def conv_exec_type(args)
  if args[1] == 'upd'
    args[1] = args[0]
    args[0] = 'upd'
  else
    td = @cfgitems[args[0]] || []
    type = td.include?(args[1]) ? 'cfg' : 'exec'
    args.unshift type
  end
end

# convert commad array
def sep_cmd(line, del = ' ', name = nil)
  line.split(del).map do |s|
    args = s.split(':')
    args.unshift(name) if name
    ignore_flg(args)
    conv_type(args)
    args
  end
end

def get_csv(base)
  open(ENV['HOME'] + "/ciax-xml/config-v1/#{base}.txt") do |f|
    f.readlines.grep(/^[!a-zA-Z0-9]/).each do |line|
      yield line.chomp.split(',')
    end
  end
end

######### Device Macro DB ##########

# Item name = site_id
def read_dev_idb(index, site)
  get_csv("idb_#{site}") do |id, gl, ck|
    item = index["#{site}_#{id}"] = {}
    item['goal'] = sep_cond(gl) { |cond| [site, cond] } if gl && !gl.empty?
    item['check'] = sep_cond(ck) { |cond| [site, cond] } if ck && !ck.empty?
  end
end

def exe_type(type, site, id)
  case type
  when 'act'
    ['exec', site, id]
  else
    @cfgitems[site] << id
    ['cfg', site, id]
  end
end

def wait_step(lop, site)
  count, cri = lop.split(':')
  wdb = {}
  if cri
    wdb['label'] = 'end of motion'
    wdb['retry'] = count
    wdb['until'] = sep_cond(cri) { |cond| [site, cond] }
  else
    wdb['sleep'] = count
  end
  wdb
end

def wait_loop(event, site)
  return unless event
  _frmcmd, lop, post = event.split('/')
  return unless lop
  wdb = wait_step(lop, site)
  wdb['post'] = sep_cmd(post, '&', site) if post
  wdb
end

# Grouping by cdb
def read_dev_cdb(index, site)
  @cfgitems[site] = []
  get_csv("cdb_#{site}") do |id, label, inv, type, cond|
    label.gsub!(/&/, 'and')
    unitting(id, label, inv, type) || next # line with cap field
    grouping(id, label, 2, site) || next   # line with ! header
    item = iteming("#{site}_#{id}", label, index)
    mk_devseq(item, id, type, cond, site)
  end
end

def mk_devseq(item, id, type, cond, site)
  seq = item['seq'] = []
  seq << exe_type(type, site, id)
  wdb = wait_loop(cond, site)
  seq << wdb if wdb
end

def mdb_reduction(index)
  index.select! do |_k, v|
    (v.key?('seq') && v['seq'].any? { |f| f.is_a? Hash }) ||
      v.key?('goal') || v.key?('check')
  end
end

def clean_unit
  @unit.values.each { |a| chk_member(a) }
  @unit.select! { |_k, v| v[:member] }
end

def clean_grp
  @group.values.each do |a|
    chk_member(a)
    chk_units(a)
  end
  @group.select! { |_k, v| v[:member] || v[:units] }
end

def chk_member(a)
  return unless a[:member]
  a[:member].replace(a[:member] & @index.keys)
  a.delete(:member) if a[:member].empty?
end

def chk_units(a)
  return unless a[:units]
  a[:units].replace(a[:units] & @unit.keys)
  a.delete(:units) if a[:units].empty?
end

######### Macro DB ##########

# Interlock DB reading
def read_mcr_idb(index, proj)
  get_csv("idb_mcr-#{proj}") do |id, gl, ck|
    con = index[id] = {}
    con['goal'] = sep_cond(gl) { |e| get_site(e) } if gl && !gl.empty?
    con['check'] = sep_cond(ck) { |e| get_site(e) } if ck && !ck.empty?
  end
end

# take macro if device macro exists
def conv_dev_mcr(ary)
  cmd, *args = ary
  if /exec/ =~ cmd
    id = args.join('_')
    ary.replace(['mcr', id]) if @mdb[:index].key?(id)
  end
  ary
end

# For select feature (substitute %? to current status)
def conv_sel(ary, select)
  return if /%./ !~ ary[1]
  select << ary[1]
  ary[1] = ary[1].sub(/%(.)/, 'X')
end

# Command DB reading
def read_mcr_cdb(index, proj)
  select = []
  get_csv("cdb_mcr-#{proj}") do |id, label, inv, type, cmds|
    label.gsub!(/&/, 'and')
    grouping(id, label, inv, proj) || next
    unitting(id, label, inv, type) || next
    item = iteming(id, label, index)
    next unless cmds && !cmds.empty?
    mk_mcrseq(item, cmds, select)
  end
  select
end

def mk_mcrseq(item, cmds, select)
  seq = item['seq'] = sep_cmd(cmds)
  seq.each do |ary|
    conv_dev_mcr(ary)
    conv_sel(ary, select)
  end
end

def read_sel_table(proj)
  db = {}
  get_csv("db_mcv-#{proj}") do |id, var, list|
    ary = list.to_s.split(' ').map { |str| str.split('=') }
    db[id] = { 'var' => var, 'list' => ary }
  end
  db
end

def mk_options(sel, dbi, str, index)
  op = sel['option'] = {}
  dbi['list'].each do |k, v|
    val = str.sub(/%./, v)
    op[k] = val if index.include?(val)
  end
end

def mk_sel(str, index, gid, db)
  id = str.sub(/%(.)/, 'X')
  dbi = db[$+].dup
  _add_i2g(gid, id)
  item = index[id] = {}
  var = dbi['var'].split(':')
  item['label'] = 'Select Macro'
  sel = item['select'] = { 'site' => var[0], 'var' => var[1] }
  mk_options(sel, dbi, str, index)
end

# Generate Select (Branch) Macros
def select_mcr(select, index, proj)
  return if select.empty?
  db = read_sel_table(proj)
  gid = "grp_sel_#{proj}"
  @group[gid] = { caption: "#{proj.upcase} Select Group", rank: 2 }
  select.each do |str|
    mk_sel(str, index, gid, db)
  end
end

######### Main ##########

if ARGV.empty?
  abort "Usage: csv2mdb -m(proj) [sites]\n"\
        "  mcr is taken by -m\n"\
        '  sites for specific macro for devices'
end
opt = ARGV.getopts('m:')
@gcore = nil
@ucore = nil
@cfgitems = {} # config command list (not action)
@devmcrs = []
@mdb = { caption_macro: 'macro' }
@group = @mdb[:group] = {}
@unit = @mdb[:unit] = {}
@index = @mdb[:index] = {}

# Convert device macro
ARGV.each do |site|
  @mdb[:caption_macro] = site
  index = {}
  read_dev_idb(index, site)
  read_dev_cdb(index, site)
  mdb_reduction(index)
  @index.update(index)
  @devmcrs.concat index.keys
end

# Convert macro
proj = opt['m']
if proj
  @mdb[:caption_macro] = proj
  index = {}
  read_mcr_idb(index, proj)
  select = read_mcr_cdb(index, proj)
  select_mcr(select, index, proj)
  @index.update(index)
end
clean_unit
clean_grp
jj @mdb
