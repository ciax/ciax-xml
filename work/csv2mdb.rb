#!/usr/bin/ruby
# IDB,CDB CSV(CIAX-v1) to MDB
#alias c2m
require 'optparse'
require 'json'

OPETBL = { '~' => '=~', '!' => '!=', '=' => '==', '^' => '!~' }

######### Shared Methods ##########

def get_site(elem)
  @skip = nil
  elem.split(':').map do|e|
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
    ope = OPETBL[$&[0]] # for '=='
    ary = [site, $`, ope, $']
    ary << @skip if @skip
    ary
  when '*', '', nil
    nil
  else
    abort "IDB: NO operator in #{cond}"
  end
end

def sep_cond(line)
  line.split('&').map do|s|
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

def _gadd(gid,uid)
  ary = @group[gid][:member]||=[]
  ary << uid unless ary.include?(uid)
  ary
end

def _uadd(uid,iid)
  ary = @unit[uid][:member]||=[]
  ary << iid unless ary.include?(iid)
  ary
end

# Group is enclosed by starting !?,----- Title ----- to next title
def grouping(id, label, inv, name)
  if /^!/ =~ id
    @gcore = "#{name}_#{$'}"
    @group[_gid]={caption: label.gsub(/ *-{2,} */, ''), rank: inv.to_i}
    return
  elsif !@gcore # default group
    @gcore = "#{name}"
    @group[_gid]={caption: "#{name.upcase} Group", rank: inv.to_i}
  end
  id
end

# Unit is enclosed by ???, Title,,cap
def unitting(id, label, inv, type)
  if type == 'cap'
    @ucore = @gcore + id.tr('^_a-zA-Z0-9', '')
    @unit[_uid]={title: id, caption: label}
    _gadd(_gid,_uid)
    return
  elsif !inv || inv.empty?
    @ucore = nil
  end
  id
end

def iteming(id, label, index)
  if @ucore
    _uadd(_uid, id)
  else
    _gadd(_gid, id)
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

# coovert cfg or upd or exec
def conv_type(args)
  return if args[0] == 'mcr'
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
  line.split(del).map do|s|
    args = s.split(':')
    args.unshift(name) if name
    ignore_flg(args)
    conv_type(args)
    args
  end
end

def get_csv(base)
  open(ENV['HOME'] + "/ciax-xml/config-v1/#{base}.txt") do|f|
    f.readlines.grep(/^[!a-zA-Z0-9]/).each do|line|
      yield line.chomp.split(',')
    end
  end
end

######### Device Macro DB ##########

# Item name = site_id
def read_dev_idb(index, site)
  get_csv("idb_#{site}") do|id, gl, ck|
    item = index["#{site}_#{id}"] = {}
    item['goal'] = sep_cond(gl) { |cond| [site, cond] } if gl && !gl.empty?
    item['check'] = sep_cond(ck) { |cond| [site, cond] } if ck && !ck.empty?
  end
end

def exe_type(type, site, id, cfga)
  case type
  when 'act'
    ['exec', site, id]
  else
    cfga << id
    ['cfg', site, id]
  end
end

def wait_loop(event, site)
  return unless event
  _frmcmd, lop, post = event.split('/')
  return unless lop
  count, cri = lop.split(':')
  wdb = {}
  if cri
    wdb['label'] = 'end of motion'
    wdb['retry'] = count
    wdb['until'] = sep_cond(cri) { |cond| [site, cond] }
  else
    wdb['label'] = 'sleep'
    wdb['sleep'] = count
  end
  wdb['post'] = sep_cmd(post, '&', site) if post
  wdb
end

# Grouping by cdb
def read_dev_cdb(index, site)
  cfga = @cfgitems[site] = []
  get_csv("cdb_#{site}") do|id, label, inv, type, cond|
    label.gsub!(/&/, 'and')
    grouping(id, label, 2, site) || next
    unitting(id, label, inv, type) || next
    item = iteming("#{site}_#{id}", label, index)
    seq = item['seq'] = []
    seq << exe_type(type, site, id, cfga)
    seq << wait_loop(cond, site)
  end
end

def mdb_reduction(index)
  index.select! do|_k, v|
    v.key?('seq') && v['seq'].any? { |f| f.is_a? Hash }
  end
  @unit.values.each{ |a| a[:member].replace(a[:member] & index.keys) }
end

######### Macro DB ##########

# Interlock DB reading
def read_mcr_idb(index, proj)
  get_csv("idb_mcr-#{proj}") do|id, gl, ck|
    con = index[id] = {}
    con['goal'] = sep_cond(gl) { |e| get_site(e) } if gl && !gl.empty?
    con['check'] = sep_cond(ck) { |e| get_site(e) } if ck && !ck.empty?
  end
end

# take macro if device macro exists
def conv_dev_mcr(ary)
  cmd, *args = ary
  if /exec/ =~ cmd
    id=args.join('_')
    ary.replace(['mcr',id]) if @mdb[:index].key?(id)
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
  get_csv("cdb_mcr-#{proj}") do|id, label, inv, type, cmds|
    label.gsub!(/&/, 'and')
    grouping(id, label, inv, proj) || next
    unitting(id, label, inv, type) || next
    item = iteming(id, label, index)
    next unless cmds && !cmds.empty?
    seq = item['seq'] = sep_cmd(cmds)
    seq.map do |ary|
      conv_dev_mcr(ary)
      conv_sel(ary, select)
    end
  end
  select
end

def read_sel_table(proj)
  db = {}
  get_csv("db_mcv-#{proj}") do|id, var, list|
    ary = list.to_s.split(' ').map { |str| str.split('=') }
    db[id] = { 'var' => var, 'list' => ary }
  end
  db
end

def mk_sel(str, index, gid, db)
  id = str.sub(/%(.)/, 'X')
  dbi = db[$+].dup
  _gadd(gid, id)
  item = index[id] = {}
  var = dbi['var'].split(':')
  item['label'] = 'Select Macro'
  sel = item['select'] = {'site' => var[0],'var' => var[1]}
  op = sel['option'] = {}
  dbi['list'].each do|k, v|
    val = str.sub(/%./, v)
    op[k] = val if index.include?(val)
  end
end

# Generate Select (Branch) Macros
def select_mcr(select, index, proj)
  return if select.empty?
  db = read_sel_table(proj)
  gid = "grp_sel_#{proj}"
  @group[gid]={caption: "#{proj.upcase} Select Group", rank: 2}
  select.each do|str|
    mk_sel(str, index, gid, db)
  end
end

######### Main ##########

abort "Usage: csv2mdb -m(proj) [sites]\n"\
      "  mcr is taken by -m\n"\
      '  sites for specific macro for devices' if ARGV.size < 1
opt = ARGV.getopts('m:')
@gcore = nil
@ucore = nil
@cfgitems = {}
@devmcrs = []
@mdb = { caption_macro: 'macro' }
@group = @mdb[:group] = {}
@unit = @mdb[:unit] = {}
@mdb[:index] = {}

# Convert device macro
ARGV.each do|site|
  @mdb[:caption_macro] = site
  index = {}
  read_dev_idb(index, site)
  read_dev_cdb(index, site)
  mdb_reduction(index)
  @mdb[:index].update(index)
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
  @mdb[:index].update(index)
end
puts JSON.dump @mdb
