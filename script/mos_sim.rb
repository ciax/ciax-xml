#!/usr/bin/env ruby
require 'libdaemon'
require 'libsimap'
require 'libsimarm'
require 'libsimbb'
require 'libsimfp'

#### Condition for Contact Sensor ####
# MODE  | MMA:POS | MFP:AO | MFP:RH || MMA:CON | MMC:CON
#-------+---------+--------+--------++---------+---------
# STORE |  -      |  -     |  -     || OFF     | ON
# LOAD  | INIT    |  -     |  -     || OFF     | OFF
# LOAD  | FOCUS   | OPEN   | OPEN   || OFF     | OFF
# LOAD  | FOCUS   | CLOSE  | OPEN   || OFF     | OFF
# LOAD  | FOCUS   | OPEN   | CLOSE  || OFF     | OFF
# LOAD  | FOCUS   | CLOSE  | CLOSE  || ON      | OFF
# LOAD  | ROT     |  -     |  -     || OFF     | OFF
# LOAD  | W-S     | CLOSE  |  -     || ON      | ON

#### Condition for Mode ####
# MMA:POS | MFP:AO || MODE
#---------+--------++------
# STORE   | OPEN   || STORE
# STORE   | CLOSE  || LOAD

# Option -d: carousel motor down
module CIAX
  # Simulator
  module Simulator
    ConfOpts.new('-(d)', options: 'd') do |cfg, _argv, opt|
      require 'libsimcar' unless opt.dry?
      Daemon.new(cfg, 54_301) do
        @sim_list.gen.run
      end
    end
  end
end
