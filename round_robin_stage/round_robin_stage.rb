require File.join(File.dirname(__FILE__), '../battle_stage')

SYSTEM_SIZE = 50
NUM_CHASERS = 5
NUM_ESCAPEES = 10
MAX_TIMESTEP = 3000
NUM_RUNS = 20

chaser_strategies = Dir.glob(File.join(File.dirname(__FILE__),"chaser_strategies/*.rb"))
escapee_strategies = Dir.glob(File.join(File.dirname(__FILE__),"escapee_strategies/*.rb"))

results = {}

chaser_strategies.each do |chaser|
  results[chaser] = {}
  escapee_strategies.each do |escapee|
    $stderr.puts "#{File.basename(chaser,'.rb')} v.s. #{File.basename(escapee,'.rb')}"
    results[chaser][escapee] = (1..NUM_RUNS).map do |i|
      $stderr.puts "  round #{i}"
      srand(i)
      load chaser
      load escapee
      stage = BattleStage.new(SYSTEM_SIZE, SYSTEM_SIZE, 5, 10)
      stage.update until stage.finished? or stage.timestep >= MAX_TIMESTEP
      $stderr.puts "    result: #{stage.timestep}"
      stage.timestep
    end
  end
end

pp results  
results.each {|k1,v1| v1.each {|k2,v2| pp v2.inject(:+).to_f/v2.size } }
