#!/usr/bin/ruby
require 'libsimap'
require 'libsimarm'
require 'libsimbb'
require 'libsimcar'
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

module CIAX::Simulator
  cfg = Conf.new
  mods = [Arm, Ap, BBIO, Carousel, FpDio]
  list = mods.map { |mod| mod.new(cfg) }
  Process.daemon(true, true)
  list.each(&:start)
  sleep
end
