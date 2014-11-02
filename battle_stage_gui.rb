require File.join(File.dirname(__FILE__), 'battle_stage')

def setup
  require 'optparse'
  opts = OptionParser.new
  opts.on("-c CHASER_SCRIPT") {|script| load script }
  opts.on("-e ESCAPEE_SCRIPT") {|script| load script }
  opts.on("-r RAND_SEED") {|seed| srand(seed.to_i) }
  opts.parse!(ARGV)

  size(700,500)
  @system_size = 50
  @total_num_escapees = 10
  @stage = BattleStage.new(@system_size,@system_size,5,@total_num_escapees)
  frame_rate(20)
  text_size(32)
  text_align(RIGHT)
end

def draw
  background(0,0,0)
  @stage.update unless @stage.finished?
  @stage.display(500,500)
  draw_sidebar
end

def draw_sidebar
  fill(255)
  rect(500,0,200,500)
  fill(192,64,64)
  text("Prize:\n #{@stage.timestep}00 Yen", 680, 40)
  fill(0,128,64)
  text_align(RIGHT)
  text("#{@stage.num_escapees} / #{@total_num_escapees}", 680, 480)
  @total_num_escapees.times do |i|
    fill(128) if @stage.num_escapees == i
    rect(640,400-30*i,30,30,2)
  end
end
