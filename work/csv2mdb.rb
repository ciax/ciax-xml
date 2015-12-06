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
    cri = $'.delete('/') # for '/S'
    ope = OPETBL[$&[0]] # for '=='
    ary = [site, $`, ope, cri]
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

# Group is enclosed by starting !?,----- Title ----- to next title
def grouping(id, label, name)
  if /^!/ =~ id
    @gcore = "#{name}_#{$'}"
    @gcap[_gid] = label.gsub(/ *-{2,} */, '')
    @gmem[_gid] = []
    return
  elsif !@gcore # default group
    @gcore = "#{name}"
    @gcap[_gid] = "#{name.upcase} Group"
    @gmem[_gid] = []
  end
  id
end

# Unit is enclosed by ???, Title,,cap
def unitting(id, label, inv, type)
  if type == 'cap'
    @ucore = @gcore + id.tr('^_a-zA-Z0-9', '')
    @ucap[_uid] = label
    @umem[_uid] = []
    @gmem[_gid] << _uid
    return
  elsif !inv || inv.empty?
    @ucore = @gcore
    unless @umem[_uid]
      @umem[_uid] = []
      @gmem[_gid] << _uid
    end
  end
  id
end

def iteming(id, label, index)
  @umem[_uid] << id
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
def sep_cmd(line, del = ' ')
  line.split(del).map do|s|
    args = s.split(':')
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
  wdb['post'] = sep_cmd(post, '&') if post
  wdb
end

# Grouping by cdb
def read_dev_cdb(index, site)
  cfga = @cfgitems[site] = []
  get_csv("cdb_#{site}") do|id, label, inv, type, cond|
    label.gsub!(/&/, 'and')
    grouping(id, label, site) || next
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
  @umem.values.each { |a| a.replace(a & index.keys) }
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
def dev_mcr(ary)
  id = ary.join('_')
  ary.replace(['mcr', id]) if @devmcrs.include?(id)
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
    grouping(id, label, proj) || next
    unitting(id, label, inv, type) || next
    item = iteming(id, label, index)
    next unless cmds && !cmds.empty?
    seq = item['seq'] = sep_cmd(cmds)
    seq.map do |ary|
      dev_mcr(ary)
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

# Generate Select (Branch) Macros
def select_mcr(select, index, proj)
  return if select.empty?
  db = read_sel_table(proj)
  gid = "sel_#{proj}"
  @gcap[gid] = "#{proj.upcase} Select Group"
  select.each do|str|
    id = str.sub(/%(.)/, 'X')
    item = index[id] = {}
    dbi = db[$+]
    var = dbi['var'].split(':')
    item['label'] = 'Select Macro'
    sel = item['select'] = {}
    sel['site'] = var[0]
    sel['var'] = var[1]
    op = sel['option'] = {}
    dbi['list'].each do|k, v|
      # For '/S' -> 'S'
      op[k.delete('/')] = str.sub(/%./, v)
    end
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
@ucap = @mdb[:caption_unit] = {}
@gcap = @mdb[:caption_group] = {}
@umem = @mdb[:member_unit] = {}
@gmem = @mdb[:member_group] = {}
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
