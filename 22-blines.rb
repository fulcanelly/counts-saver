require 'opengl'
require 'glut'
require 'benchmark'

include Gl, Glut
#run in such way
# ruby --jit-wait --jit --jit-verbose=1 --jit-save-temps --jit-max-cache=1000 --jit-min-calls=1000 22-blines.rb
PI = 3.14159
KOEF = PI / 180


class Coord
    attr_accessor :x, :y

    def initialize(x, y)
        @x = x
        @y = y 
    end

    def draw_line(to)
        glBegin(GL_LINES);
            glVertex2f(x, y);
            glVertex2f(to.x, to.y);
        glEnd();
    end

    def distance(another_coord)
        Math.sqrt(
            (@x - another_coord.x)**2 + 
            (@y - another_coord.y)**2
        )
    end

    def +(another_coord)
        Coord.new(
            x + another_coord.x,
            y + another_coord.y 
        )
    end
end

class Ball

    attr_accessor :center, :radius, :speed
    attr_accessor :cache 
    
    def initialize(center, radius, speed)
        
        @radius, @center, @speed = radius, center, speed
        @cache = Array.new()

        0.step(360, 24) do |degree|
            x = Math.cos(degree * KOEF) * radius
            y = Math.sin(degree * KOEF) * radius
            @cache << Coord.new(x, y)
        end

    end
    
    def draw_circle 

        glBegin(GL_POLYGON)

        @cache.each do |dot|
            glVertex2f(dot.x + center.x, dot.y + center.y)
        end

        glEnd()
        
    end

   

    def regenerate
        center.x = rand 0...BallsLines.instance.border.x
        center.y = rand 0...BallsLines.instance.border.y
    end

    RANGE = -0.3..0.3
    def mutate_speed

        @speed += Coord.new rand(RANGE), rand(RANGE)
    end

    def move(border)
        unless (0..border.x).include?(center.x) and (0..border.y).include?(center.y)
            regenerate()
        end

        mutate_speed() if rand > 0.6 
        
        self.center += self.speed
    end

end

class BallsLines 

    def self::instance()
        @i ||= BallsLines.new 200
    end

    attr_accessor :all_vertexes
    attr_accessor :border 

    def rand_cord()
        x = rand(0...border.x)
        y = rand(0...border.y)
        Coord.new(x, y)
    end

    def generate_ball()
        center = rand_cord()
        speed = Coord.new rand(-1..1.0), rand(-1..1.0) 
    
        radius = rand(5..20)

        Ball.new(center, radius, speed)
    end

    def initialize(size)

        @border = Coord.new(200, 200)

        @all_vertexes = []

        size.times do
            @all_vertexes << generate_ball()
        end

    end

    def draw 
    
        #drawing balls
        glColor3f(0.6, 0.6, 0.6)
        
        all_vertexes.each do |vertex|
            vertex.draw_circle
        end

        #drawing lines
        glColor3f(0.8, 0.8, 0.8)

        all_vertexes.each_with_index do |from, index|

            all_vertexes[index + 1..-1].each do |targer| 
                
                point, target = from.center, targer.center
                point.draw_line(target) if point.distance(target) < 200
                            
            end
        
        end

        #moving 
        all_vertexes.each do |vertex_one|
            vertex_one.move(border)
        end

    end
end

@blines =  BallsLines.instance()

display = Proc.new do
    glClear(GL_COLOR_BUFFER_BIT)
    GL.LoadIdentity

    puts Benchmark.measure { 
        @blines.draw()
    }

    glutSwapBuffers()
end
  
reshape = Proc.new do |w, h|
    @blines.border = Coord.new(w, h)
    glViewport(0, 0,  w,  h)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrtho(0.0, w, 0.0, h, -1.0, 1.0)
    glMatrixMode(GL_MODELVIEW)
end
  
timer = Proc.new do |i|
    glutPostRedisplay()
    glutTimerFunc(1000/60, timer, 0)
end

glutInit
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB)
glutInitWindowSize(700, 400)
glutInitWindowPosition(100, 100)
glutCreateWindow("balls and lines v.3.1")

glClearColor(0.0, 0.4, 0.4, 1.0);
glutReshapeFunc(reshape)
glutDisplayFunc(display)

glutTimerFunc(0,timer,0)
glutMainLoop
