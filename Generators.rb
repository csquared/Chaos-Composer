#module Generators by Chris Continanza
# 
# Generators are the chaotic equations I am using to generate the sequences of numbers
# that are sent to the EventTree to analyze.  
# The ChaosGenerator class provides a 'step' method, which is used to create the run.
#
# The Henon generator overrides the 'step' method because its not defined as a dimensionless equation
# The rest provide 'get_x', 'get_y', and 'get_z' methods to use the three-dimensional runge-kutta
# integration.
#
# 'Step' returns one number because I am using only one dimension of the equation to basically wind up with an
# array of numbers.  This array represents a generation of the first N numbers of x for the
# given chaotic equation, and should reflect both variation and similarity.  IE- better
# than random for music generation.

# requires not needed b.c this is a module-- left for reference
# require 'rubygems'
 
# require 'midilib/sequence'
# require 'midilib/consts'
# include MIDI


#global functions
def print_array(array)
  puts '[' + array.join(',') + ']'
end


module Generators
  
  #abstract class
  #requires child to implement method 'step'
  class ChaosGenerator    
      #return array of n values from function
     def raw_compose(n)
       score = []
       n.times do
         x = self.step
         score << x
       end
       score
     end
   
     #return scaled_array of n values from 0 to 100
     def compose(n, spread)
       score = []
       n.times do
         x,y,z = self.step
         score << x.abs
       end
       max = score.dup.sort.last
       score.collect{ |num| (num/max * spread).to_i }
     end
     
     def self.raw_compose_runs(n_runs, n)
       runs = []
       eq = self.standard
       n_runs.times do
         runs << eq.raw_compose(n)
       end
       runs
     end
    
     def self.compose_runs(n_runs, n, spread)
       runs = []
       eq = self.standard
       n_runs.times do
         runs << eq.compose(n, spread)
       end
       runs
     end
  
    #step function for integration
    def step
      @x,@y,@z = runge_kutta(@x,@y,@z, @step)
    
      return @x
    end
    
    #runge kutta integration  
    def runge_kutta(x, y, z, step)
      x1 = get_x(x,y,z)
      y1 = get_y(x,y,z)
      z1 = get_z(x,y,z)
      dxx = x + 0.5 * step * x1
      dyy = y + 0.5 * step * y1
      dzz = z + 0.5 * step * z1
      x2 = get_x(dxx,dyy,dzz)
      y2 = get_y(dxx,dyy,dzz)
      z2 = get_z(dxx,dyy,dzz)
      dxx = x + 0.5 * step * x2
      dyy = y + 0.5 * step * y2
      dzz = z + 0.5 * step * z2
      x3 = get_x(dxx,dyy,dzz)
      y3 = get_y(dxx,dyy,dzz)
      z3 = get_z(dxx,dyy,dzz)
      dxx = x + 0.5 * step * x3
      dyy = y + 0.5 * step * y3
      dzz = z + 0.5 * step * z3
      x4 = get_x(dxx,dyy,dzz)
      y4 = get_y(dxx,dyy,dzz)
      z4 = get_z(dxx,dyy,dzz)
      dxx = x + 0.5 * step * x4
      dyy = y + 0.5 * step * y4
      dzz = z + 0.5 * step * z4
      
      x += (step/6.0) * (x1 + 2.0 * x2 + 2.0 * x3 + x4)
      y += (step/6.0) * (y1 + 2.0 * y2 + 2.0 * y3 + y4)
      z += (step/6.0) * (z1 + 2.0 * z2 + 2.0 * z3 + z4)
      return x,y,z
    end
    
  end


  #Henon Attractor
  class Henon < ChaosGenerator
    def self.standard
      return self.new
    end
  
    def initialize
      @x, @y = 1.0, 1.0
    end
    
    def step
      x,y = @x,@y
      
      @x = (y + 1) - (1.4 * (x ** 2))
      @y = 0.3 * x
      
      return @x
    end
        
    def scale_output(x)
      x * 10
    end
  end

  #Lorenz Attractor
  class Lorenz < ChaosGenerator
    def self.standard
      return self.new(10, 28, 8/3)
    end
  
    def initialize(_delta, _r, _b)
      @delta = _delta.to_f
      @r = _r.to_f
      @b = _b.to_f
      @x, @y, @z = 1.0,1.0,1.0
      @step = 0.01
    end
  
    
    def get_x(x,y,z)
      (-1 * @delta) * (x-y)
    end
    
    def get_y(x,y,z)
      @r * x - y - x * z
    end
    
    def get_z(x,y,z)
      x * y - @b * z
    end
    
    
  end

  #Rossler Attractor
  class Rossler < ChaosGenerator
    def self.standard
      return self.new(0.1,0.1,14)
    end
    
    def initialize(_a, _b, _c)
      @A, @B, @C = _a, _b, _c
      @x, @y, @z = 1.0,1.0,1.0
      @step = 0.1
    end
  
    def get_x(x,y,z)
      0 - y - x
    end
    
    def get_y(x,y,z)
      x + @A*y
    end
    
    def get_z(x,y,z)
      @B + x * z - @C * z 
    end
  end

  #Chua Attractor
  class Chua < ChaosGenerator
  
    def self.standard
      return self.new(9.3515908493,14.7903198054,-1.1384111956,-0.7224511209,1.0,0.0160739649)
    end

  
    def initialize(_alpha, _beta, _a, _b, _k, _y)
      @@alpha = _alpha #9.3515908493
      @@beta = _beta #14.7903198054
      @@a = _a #-1.1384111956
      @@b = _b #-0.7224511209
      @@k = _k #1
      @@y = _y #0.0160739649
      @x, @y, @z = 1,1,1
      @step = 0.01
     end
     
     def get_x(x,y,z)
       @@k * @@alpha * (y - x - f(x))
     end

     def get_y(x,y,z)
       @@k * (x - y + z)
     end

     def get_z(x,y,z)
       @@k * ( -1 * @@beta * y - @@y * z ) 
     end
  
      def f(x)
        return (@@b * x) + (0.5 * ((@@a - @@b) * ((x+1).abs - (x-1).abs)))
      end
  end
  
end 

include Generators

#bell_aston = BellAston.new
if(__FILE__ == $0 )
  eq = Chua.standard
  raw = Henon.standard
  10.times do
    puts '[' + eq.compose(100,4*12).join(',') + ']'
    #puts '[' + raw.raw_compose(100).join(',') + ']'
  end
end




