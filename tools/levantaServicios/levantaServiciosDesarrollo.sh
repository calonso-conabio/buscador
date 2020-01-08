#! /bin/bash

/usr/bin/redis-server > log/bitacoraScript.log &
rails runner "eval(File.read 'tools/levantaServicios/levantaBlurrily.rb')" &

