#!/usr/bin/ruby
# IDB,CDB CSV(CIAX-v1) to MDB
#alias c2m
require 'optparse'
require 'json'
abort "Usage: csv2mdb -m(proj) [sites]\n"\
      "  mcr is taken by -m\n"\
      '  sites for specific macro for devices' if ARGV.size < 1
opt = ARGV.getopts('m:')
@ope = { '~' => 'match', '!' => 'not', '=' => 'equal', '^' => 'unmatch' }
@gid = nil
@uid = nil
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
    ope = @ope[$&[0]] # for '=='
    ary = [ope, cri, site, $`]
    ary << @skip if @skip
    ary
  when '*', '', nil
    nil
  else
    abort "IDB: NO operator in #{cond}"
  end
end

def spl_cond(line)
  line.split('&').map do|s|
    site, cond = yield s
    mk_cond(site, cond)
  end.compact
end

def spl_cmd(line, del = ' ')
  line.split(del).map do|s|
    ary = s.split(':')
    if /^!/ =~ ary[0]
      ary[0] = $'
      ary << true
    end
    # take macro if device macro exists
    id = ary.join('_')
    ary = @devmcrs.include?(id) ? ['mcr', id] : ary
    # add cfg or upd or exec
    unless ary[0] == 'mcr'
      if ary[1] == 'upd'
        ary[1] = ary[0]
        ary[0] = 'upd'
      else
        td = @cfgitems[ary[0]] || []
        type = td.include?(ary[1]) ? 'cfg' : 'exec'
        ary.unshift type
      end
    end
    ary
  end
end

# Group is enclosed by starting !?,----- Title ----- to next title
def grouping(id, label, name, mid)
  if /^!/ =~ id
    @gid = "grp_#{name}#{$'}"
    @gcap[@gid] = label.gsub(/ *-{2,} */, '')
    @gmem[@gid] = []
    return
  elsif !@gid
    @gid = "grp_#{name}"
    @gcap[@gid] = "#{name.upcase} Group"
    @gmem[@gid] = []
  end
  if @gid
    if @uid
      @gmem[@gid] << @uid unless @gmem[@gid].include?(@uid)
    else
      @gmem[@gid] << mid
    end
  end
  id
end

# Unit is enclosed by ???, Title,,cap
def unitting(id, label, inv, type, prefix = nil)
  if type == 'cap'
    @uid = 'unit_' + id.tr('^_a-zA-Z0-9', '')
    @ucap[@uid] = label
    @umem[@uid] = []
    return
  elsif !inv || inv.empty?
    @uid = nil
  end
  id = "#{prefix}_#{id}" if prefix
  @umem[@uid] << id if @uid
  id
end

def get_csv(base)
  open(ENV['HOME'] + "/ciax-xml/config-v1/#{base}.txt") do|f|
    f.readlines.grep(/^[!a-zA-Z0-9]/).each do|line|
      yield line.chomp.split(',')
    end
  end
end

@mdb = { caption_macro: 'macro' }
@cfgitems = {}
@devmcrs = []
@ucap = @mdb[:caption_unit] = {}
@gcap = @mdb[:caption_group] = {}
@umem = @mdb[:member_unit] = {}
@gmem = @mdb[:member_group] = {}
@mdb[:index] = {}
# Convert device
ARGV.each do|site|
  @mdb[:caption_macro] = site
  index = {}
  cfga = @cfgitems[site] = []
  # Item name = site_id
  get_csv("idb_#{site}") do|id, gl, ck|
    con = index["#{site}_#{id}"] = {}
    con['goal'] = spl_cond(gl) { |cond| [site, cond] } if gl && !gl.empty?
    con['check'] = spl_cond(ck) { |cond| [site, cond] } if ck && !ck.empty?
  end
  # Grouping by cdb
  get_csv("cdb_#{site}") do|id, label, inv, type, cmd|
    label.gsub!(/&/, 'and')
    mid = unitting(id, label, inv, type, site) || next
    grouping(id, label, site, mid) || next
    con = (index[mid] ||= {})
    con['label'] = label
    seq = con['seq'] = []
    case type
    when 'act'
      seq << ['exec', site, id]
    else
      cfga << id
      seq << ['cfg', site, id]
    end
    if cmd
      _, mid, post = cmd.split('/')
      if mid
        rtry, cri, = mid.split(':')
        wait = {}
        if cri
          wait['retry'] = rtry
          wait['label'] = 'end of motion'
          wait['until'] = spl_cond(cri) { |cond| [site, cond] }
        else
          wait['sleep'] = rtry
          wait['label'] = 'sleep'
        end
        wait['post'] = spl_cmd(post, '&') if post
        seq << wait
      end
    end
  end
  index.select! do|_k, v|
    v.key?('seq') && v['seq'].any? { |f| f.is_a? Hash }
  end
  @mdb[:index].update(index)
  @devmcrs.concat index.keys
end

# Convert @mdb
proj = opt['m']
if proj
  @mdb[:caption_macro] = proj
  index = {}
  # Interlock DB reading
  get_csv("idb_mcr-#{proj}") do|id, gl, ck|
    con = index[id] = {}
    con['goal'] = spl_cond(gl) { |e| get_site(e) } if gl && !gl.empty?
    con['check'] = spl_cond(ck) { |e| get_site(e) } if ck && !ck.empty?
  end
  select = []
  # Command DB reading
  get_csv("cdb_mcr-#{proj}") do|id, label, inv, type, seq|
    label.gsub!(/&/, 'and')
    unitting(id, label, inv, type) || next
    grouping(id, label, proj, id) || next
    con = (index[id] ||= {})
    con['label'] = label.gsub(/&/, 'and')
    # For select feature (substitute %? to current status)
    con['seq'] = spl_cmd(seq).map do|ary|
      if /%./ =~ ary[1]
        select << ary[1]
        ary[1] = ary[1].sub(/%(.)/, 'X')
      end
      ary
    end if seq && !seq.empty?
  end
  @mdb[:index].update(index)
  # Generate Select (Branch) Macros
  unless select.empty?
    db = {}
    get_csv("db_mcv-#{proj}") do|id, var, list|
      ary = list.to_s.split(' ').map { |str| str.split('=') }
      db[id] = { 'var' => var, 'list' => ary }
    end
    gid = "sel_#{proj}"
    @gcap[gid] = "#{proj.upcase} Select Group"
    index = {}
    select.each do|str|
      id = str.sub(/%(.)/, 'X')
      con = index[id] = {}
      dbi = db[$+]
      var = dbi['var'].split(':')
      con['label'] = 'Select Macro'
      sel = con['select'] = {}
      sel['site'] = var[0]
      sel['var'] = var[1]
      op = sel['option'] = {}
      dbi['list'].each do|k, v|
        # For '/S' -> 'S'
        op[k.delete('/')] = str.sub(/%./, v)
      end
    end
    @mdb[:index].update(index)
  end
end
puts JSON.dump @mdb
