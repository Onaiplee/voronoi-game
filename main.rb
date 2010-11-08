# -*- coding: utf-8 -*-
require 'socket'
host, port = ARGV

######### First divide the whole grid in to 50X50 sub squares ########
squares = Array.new(50) { Array.new(50,0) }
$values = Array.new(50) { Array.new(50,0) }
def center(square_x, square_y)
  [square_x * 8 + 4, square_y * 8 + 4]
end

def to_square(x, y)
  [x/8, y/8]
end

def dist(p1, p2)
  (p1[0] - p2[0])**2 + (p1[1] - p2[1])**2
end
  


p1 = center(13,13)
p2 = center(13,36)
p3 = center(36,13)
p4 = center(36,36)

hight_value = dist(p1,[0,0])  
0.upto(49) do |x_square|
  0.upto(49).each_with_index do |y_square|
    x, y = center(x_square, y_square)
    if x_square <= 25 && y_square <= 25
      $values[x_square][y_square] = hight_value - dist([x,y],p1)
    elsif x_square <= 25 && y_square > 25
      $values[x_square][y_square] = hight_value - dist([x,y],p2)
    elsif x_square > 25 && y_square <= 25
      $values[x_square][y_square] = hight_value - dist([x,y],p3)
    else
      $values[x_square][y_square] = hight_value - dist([x,y],p4)
    end
  end
end

#puts $values[10][10]
#print "hahahahah\n"

def evaluate(next_x, next_y, stones)
  raw_score_array = Array.new($no_of_players, 0)
  x_s, y_s = center(next_x, next_y)
  stones.push([x_s,y_s,$my_play_no])
  0.upto(49) do |x|
    0.upto(49) do |y|
      center_x, center_y = center(x, y)
      min = 10000000
      index = -1
      stones.each_with_index do |s,idx|
        if dist([center_x,center_y],[s[0],s[1]]) < min
          min = dist([center_x,center_y],[s[0],s[1]])
          index = idx
        end
      end
      score = $values[x][y]#*1.0/min  # float conversion?
      print score, "\n"
      if index == -1
        raise "index is -1"
      end
      player = stones[index][2]
      raw_score_array[player - 1] += score
    end
  end
  myscore = raw_score_array[$my_play_no -1]
  raw_score_array[$my_play_no] = 0
  max = -100000
  raw_score_array.each do |s|
    if s > max
      max = s
    end
  end
  stones.pop
  return myscore - max 
end
     
others_moves_queue = Array.new()
stones = Array.new()
s = TCPSocket.open(host, port)
while line = s.gets
  puts line.chop
  if line =~ /^\d+ \d+ \d+ \d+$/
    dimen, no_of_turn, $no_of_players, $my_play_no = line.split(' ')
    $no_of_players = $no_of_players.to_i
    $my_play_no = $my_play_no.to_i
  elsif line =~ /^\d+ \d+ \d+$/
    x, y, player_no = line.split(' ')
    x = x.to_i
    y = y.to_i
    player_no = player_no.to_i
    others_moves_queue.push([player_no, x, y])
  elsif line =~ /^YOURTURN$/
    if others_moves_queue.length == 0
      if $my_play_no != 1
        raise "my_play_no isn't 1 but I have to do the first turn"
      end
      next_x, next_y = center(12,12)
      stones.push([next_x, next_y, $my_play_no])
      s.puts "#{next_x} #{next_y}"
      # make the first move and update the squares #
    else
      while others_moves_queue.length != 0 do
        player_to_move, move_x, move_y = others_moves_queue.shift
        stones.push([move_x, move_y, player_to_move])
        #puts "oponent move #{move_x} #{move_y}"
        square_x, square_y = to_square(move_x, move_y)
        squares[square_x][square_y] = 1
      end
      
      net_max = -100000
      next_xx = -1
      next_yy = -1
      squares.each_with_index do |i,x|
        i.each_with_index do |j,y|
          if j == 0
            if evaluate(x,y,stones) > net_max
              net_max = evaluate(x, y, stones)
              next_xx = x
              next_yy = y
            end
          end
        end
      end
      if (next_xx == -1) || (next_yy == -1)
        raise "next_x or next_y equals -1"
      end
      stones.push([next_xx, next_yy, $my_play_no])
      s.puts "#{next_xx} #{next_yy}"
    end
  elsif line =~ /^WIN$/ || line =~ /^LOSE$/
    print "I got a "
    puts line
    break
  else
    raise "Unknown clause!"
  end
end
s.close


