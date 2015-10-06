#!/usr/bin/ruby
require 'libwatrsp'

# View is not used for computing, just for apperance for user.
# So the convert process (upd) will be included in to_s
module CIAX
  # Watch Layer
  module Wat
    # Decorate the event data (Put caption,symbole,etc.) from WDB
    class View < Upd
      def initialize(event)
        super()
        @event = type?(event, Event).upd
        wdb = type?(event.dbi, Dbi)[:watch] || { index: [] }
        @event.post_upd_procs << proc do
          verbose { 'Propagate Event#upd -> upd' }
          upd
        end
        init_stat(wdb)
        upd
      end

      def to_v
        str = time_elps
        str << time_next
        str << time_act
        str << item('Issuing', self['exec'])
        return str if self['stat'].empty?
        str << view_cond
      end

      def to_r
        @event.to_r
      end

      private

      def init_stat(wdb)
        self['stat'] = {}
        wdb[:index].each do |id, evnt|
          hash = (self['stat'][id] ||= {})
          hash['label'] = evnt['label']
          init_cond(evnt[:cnd], (hash['cond'] ||= []))
        end
        self
      end

      def init_cond(cond, m)
        cond.each do |cnd|
          m << Hash[cnd]
          m.last['cri'] = cnd['val'] if cnd['type'] != 'onchange'
        end
        self
      end

      def time_elps
        item('Elapsed', elps_date(self['time'], now_msec))
      end

      def time_act
        item('ActiveTime', elps_sec(self['act_start'], self['act_end']))
      end

      def time_next
        item('ToNextUpdate', elps_sec(now_msec, self['upd_next']))
      end

      def item(str, res = nil)
        '  ' + color(str, 2) + "\t: #{res}\n"
      end

      def view_cond
        str = item('Conditions')
        conditions(str)
        str << item('Interrupt', self['int'])
        str << item('Blocked', self['block'])
      end

      def upd_core
        self['time'] = @event['time']
        %w(exec block int act_start act_end upd_next).each do |id|
          self[id] = @event.get(id)
        end
        upd_stat
        self
      end

      def upd_stat
        self['stat'].each do |id, v|
          upd_cond(v['cond'], id, v)
          v['active'] = @event.get('active').include?(id)
        end
        self
      end

      def upd_cond(cond, id, v)
        cond.each_index do |i|
          h = v['cond'][i]
          var = h['var']
          h['val'] = @event.get('crnt')[var]
          h['res'] = @event.get('res')[id][i]
          h['cri'] = @event.get('last')[var] if h['type'] == 'onchange'
        end
        self
      end

      def conditions(str)
        self['stat'].values.each do |i|
          str << '    ' + color(i['label'], 6) + "\t: "
          str << show_res(i['active']) + "\n"
          i['cond'].each { |j| str << sub_cond(j) }
        end
      end

      def sub_cond(j)
        str = '      ' + show_res(j['res'], 'o', 'x') + ' '
        str << color(j['var'], 3) + '  '
        ope = j['inv'] ? '!~' : '=~'
        str << "(#{j['type']}: "
        if j['type'] == 'onchange'
          str << "#{j['cri']} => #{j['val']}"
        else
          str << "/#{j['cri']}/ #{ope} #{j['val']}"
        end
        str << ")\n"
      end

      def head(str, clr)
        '    ' + color(str, clr) + "\t: "
      end

      def show_res(res, t = nil, f = nil)
        res ? color(t || res, 2) : color(f || res, 1)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      OPT.parse('r')
      event = Event.new
      begin
        id = STDIN.tty? ? ARGV.shift : event.read['id']
        dbi = Ins::Db.new.get(id)
        event.setdbi(dbi).ext_save.ext_load if STDIN.tty?
        wview = View.new(event)
        puts STDOUT.tty? ? wview : wview.to_j
      rescue InvalidID
        OPT.usage('(opt) [site] | < event_file')
      end
    end
  end
end
