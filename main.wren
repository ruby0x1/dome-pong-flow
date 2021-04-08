import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard
import "dome" for Window
import "random" for Random

//A simple pong like game,
//made for dome jam https://itch.io/jam/domejam
//made using dome engine https://domeengine.com
//written in Wren http://wren.io
//made by ruby0x1  https://twitter.com/ruby0x1

//Concept
//The basic concept is to keep the ball moving. Instead of a miss being 
//a failure and a reset (which breaks the game flow), we wrap the ball 
//instead of bouncing off walls or failing if missed.

//To win, instead of making it failure based, success is used. 
//If you hit the ball, you gain a point, and the first to a certain number wins.

//Also on the theme of flow, when you do hit the ball, the screen is rotated.
//This keeps players on their toes and the game flowing by requiring slightly
//faster reflexes and thinking ahead/predicting.

var RNG = Random.new()
var White = Color.rgb(255,255,255,200)
var Pink = Color.hex("#f6007c")
var Blue = Color.hex("#007cf6")
var Debug = false

class State {
  static title      { 0 }
  static countdown  { 1 }
  static game       { 2 }
  static end        { 3 }
}

class PongFlow {

  ball { _ball }
  paddle0 { _paddle0 }
  paddle1 { _paddle1 }

  construct new(){}
  init() {
    
    _things = []
    _keys = Keys.new(["Space", "W", "A", "S", "D", "Left", "Right", "Up", "Down", "0"])

    _state = State.title

      //some things
    _paddle0 = Paddle.new(0, Pink)
    _paddle1 = Paddle.new(1, Blue)
    _ball = Ball.new()
      //countdown information
    _count = 0
    _count_next = 0
      //win information
    _winner = null
    _win_score = 8

      //we do everything via the space key for simplicity
    released("Space") {
      if(_state == State.title) {
        countdown_start()
      } else if(_state == State.end || _state == State.game) {
        reset()
        _state = State.title
      }
    }

  } //init

  //things 'system'

    thing_add(thing) { _things.add(thing) }
    thing_remove(thing) {
      var index = Lists.find(_things, thing)
      if(index >= 0) _things.removeAt(_things)
    }

  //game helpers

    reset() {
      _paddle0.score = 0
      _paddle0.which = 0
      _paddle0.orient = Orient.default
      _paddle0.y = 0.5

      _paddle1.score = 0
      _paddle1.which = 1
      _paddle1.orient = Orient.default
      _paddle1.y = 0.5

      _ball.x = _ball.y = 0.5
      _winner = null
    } //reset

    countdown_start() {
      _count = 0
      _state = State.countdown
      _count_next = System.clock + 1
    }

    check_score(paddle, value) {
      if(value >= _win_score) {
        _winner = paddle
        _state = State.end
      }
    }

  //updates
    
    update() {

      //always update the key system for input
      _keys.update()

      //update states
      if(_state == State.game) {
        update_game()
      } else if(_state == State.countdown) {
        update_countdown()
      }

    } //update

    update_game() {
      _things.each {|thing| thing.update() }
    }

    update_countdown() {
      var now = System.clock
      if(now >= _count_next) {
        _count_next = System.clock + 1
        _count = _count + 1
        if(_count == 4) {
          _state = State.game
        }
      }
    }


  //drawing
    
    draw(dt) {

      Canvas.cls(Color.white)
      _things.each {|thing| thing.draw(dt) }

      if(Debug) text("%(_state)", 0, Color.black)

      if(_state == State.title) {
        draw_title()
      } else if(_state == State.countdown) {
        draw_countdown()
      } else if(_state == State.end) {
        draw_end()
      }

    } //draw

    draw_end() {

      Canvas.rectfill(0, 0, Canvas.width, Canvas.height, White)

      var text_y = Canvas.height*0.2
      text("GAME DONE!", text_y, Color.black)

      text_y = text_y + 16
      text("PRESS SPACE TO END", text_y, Color.purple)

      text_y = text_y + 80
      text("WINNER", text_y, _winner.color)

    } //draw_end

    draw_countdown() {

      Canvas.rectfill(0, 0, Canvas.width, Canvas.height, White)

      var text_y = Canvas.height*0.2
      text("READY%("?"*(1+_count))", text_y, Color.black)

      text_y = text_y + 16
      if(_count > 0) {
        for(i in 0 ... _count) {
          text("%(3 - i)", text_y, Pink)
          text_y = text_y + 16
        }
      }

    } //draw_countdown

    draw_title() {

      Canvas.rectfill(0, 0, Canvas.width, Canvas.height, White)

      var text_y = Canvas.height*0.2
      text("PONG FLOW", text_y, Color.black)

      text_y = text_y + 14
      text("(a tiny dome engine game)", text_y, Color.black)

      text_y = text_y + 16
      text("PRESS SPACE TO START", text_y, Color.purple)

      //bottom text

      text_y = text_y + 80
      text("Player 1: WASD", text_y, Pink)

      text_y = text_y + 12
      text("Player 2: Arrows", text_y, Blue)

      text_y = text_y + 12
      text("play till %(_win_score)", text_y, Color.black)
  
    } //draw_title

  //input bindings

    down(key, fn) { _keys.bind_down(key, fn) }
    pressed(key, fn) { _keys.bind_pressed(key, fn) }
    released(key, fn) { _keys.bind_released(key, fn) }

  //helpers

      //draws text center screen. text is 8 units wide
    text(string, y, color) {
      Canvas.print(string, Canvas.width*0.5 - (string.count*0.5) * 8, y, color)
    }

      //rectangle overlap function, for collision
    overlap(x,y,w,h,  other_x, other_y, other_w, other_h) {
      if(x > other_x + other_w) return false
      if(y > other_y + other_h) return false
      if(x + w < other_x) return false
      if(y + h < other_y) return false
      return true
    }

      //length or magnitude of a 2d vector
    length(x, y) { (x * x + y * y).sqrt }
      //sign of a number (0 being positive)
    sign(num) { num < 0 ? -1 : 1 }

} //PongFlow

var Game = PongFlow.new()

//thing
  
  class Thing {
    
    x { _x }
    y { _y }
    x = (value) { _x = value } 
    y = (value) { _y = value }

    construct new(x, y) { 
      _x = x
      _y = y
      Game.thing_add(this)
    }

    draw(dt) {}
    update() {}
    destroy() {
      Game.thing_remove(this)
    }

  }

//ball

  class Ball is Thing {

    radius { 8 }
    
    draw_x { Canvas.width * x }
    draw_y { Canvas.height * y }

    bound_x { draw_x - radius }
    bound_y { draw_y - radius }
    bound_w { (radius * 2) }
    bound_h { (radius * 2) }

    construct new() {

      super(0.5, 0.5)

        //these numbers are tiny because our x/y is in 0...1 range
      _vel_max = 0.008
      _vel_min = 0.005

        //pick a random starting speed/direction
      _vel_x = RNG.float() * _vel_max
      _vel_y = RNG.float() * _vel_max
        
        //don't let it move too slow, that's boring
      if(_vel_x < _vel_min) _vel_x = _vel_min
      if(_vel_y < _vel_min) _vel_y = _vel_min

        //flip at random, so who gets the ball first is variable
      if(RNG.int(2) == 0) _vel_x = _vel_x * -1
      if(RNG.int(2) == 0) _vel_y = _vel_y * -1

        //if we bounce, we prevent collision
        //for a little while so it doesn't rapidly
        //bounce unpredictably and double score
        //the cooloff is in seconds, how long to ignore collisions
      _can_collide = true
      _collide_timer = 0
      _collide_cooloff = 1

    } //new

    draw(dt) {

      Canvas.circlefill(draw_x, draw_y, radius, Color.black)

      if(Debug) {
        var color = _can_collide ? Color.black : Color.red
        Canvas.rect(bound_x, bound_y, bound_w+1, bound_h+1, color)
      }

    } //draw

    bounce(x, y) {

      if(!_can_collide) return false
      _can_collide = false

        //how fast are we going? we need the magnitude
        //so we can preserve the speed, but change direction
      var speed = Game.length(_vel_x, _vel_y)

        //find the direction we're headed, 
        //reflect it based on input x/y values,
        //and then add randomness into it
      var dir_x = Game.sign(_vel_x) * x * RNG.float()
      var dir_y = Game.sign(_vel_y) * y * RNG.float()
        //normalize the direction so it's 0..1
      var dir_len = Game.length(dir_x, dir_y)
      dir_x = dir_len != 0 ? dir_x/dir_len : 0
      dir_y = dir_len != 0 ? dir_y/dir_len : 0
        //then scale it back up by the speed we were going
      _vel_x = dir_x * speed
      _vel_y = dir_y * speed

        //prevent collision briefly 
      _collide_timer = System.clock + _collide_cooloff

    } //bounce

    update() {

        //update position
      x = x + _vel_x
      y = y + _vel_y

        //handle screen wrapping
      if(bound_y > Canvas.height)   { y = 0 }
      if(bound_y+bound_h < 0)       { y = 1 }
      if(bound_x > Canvas.width)    { x = 0 }
      if(bound_x+bound_w < 0)       { x = 1 }

        //update collision cool off
      if(System.clock >= _collide_timer) {
        _can_collide = true
      }
      
    } //update

  } //Ball

//paddle

    //an enum for paddle orientation
  class Orient {
    static vertical { 0 }
    static horizontal { 1 }
    static default { Orient.vertical }
  }

  class Paddle is Thing {

    speed  { 0.025 }  //how fast a paddle moves (0...1 range for whole screen)
    offset { 8 }      //how far away from a wall a paddle is 
    base_w { 32 }     //the base size for a paddle
    base_h { 16 }

    which      { _which }     //either 0 or 1, for where on screen they are
    which=(v)  { _which=v }
    color      { _color }     //drawing color
    orient     { _orient }    //orientation
    orient=(v) { _orient=v }
    score      { _score }     //score
    score=(v)  { _score=v }

    //width and height is based on current orientation
    draw_w { _orient == Orient.vertical ? base_h : base_w }
    draw_h { _orient == Orient.vertical ? base_w : base_h }

    //draw x is used so that y can happen in a normalized range
    draw_x {
      if(_orient == Orient.vertical) {
        return offset + (_which * (Canvas.width - (offset * 2) - draw_w))
      } else {
        var range = (Canvas.width - base_w)
        var in_range = y * range
        return in_range
      }
    } //draw_x

    draw_y {
      if(_orient == Orient.vertical) {
        var range = (Canvas.height - base_w)
        var in_range = y * range
        return in_range
      } else {
        return offset + (_which * (Canvas.height - (offset * 2) - draw_h))
      }
    } //draw_y
    
    construct new(which, color) {

      //we only use y as the location along a wall, between 0 and 1
      super(0, 0.5) 

      _which = which
      _color = color
      _orient = Orient.vertical
      _keys = {
        "left"  : _which == 0 ? "A" : "Left",
        "right" : _which == 0 ? "D" : "Right",
        "up"    : _which == 0 ? "W" : "Up",
        "down"  : _which == 0 ? "S" : "Down",
      }

      _score = 0

      if(Debug) {
        Game.released("0") {
          flow()
        }
      }

    } //new

    left  { Keyboard.isKeyDown(_keys["left"]) || Keyboard.isKeyDown(_keys["up"]) }
    right { Keyboard.isKeyDown(_keys["right"]) || Keyboard.isKeyDown(_keys["down"]) }
    
    reorient() {
      if(_orient == Orient.vertical) {
        _orient = Orient.horizontal
      } else {
        _orient = Orient.vertical
      }
    } //reorient

    draw(dt) {
      Canvas.rectfill(draw_x, draw_y, draw_w, draw_h, _color)
      Canvas.print("%(_score)", draw_x+draw_w*0.5-4, draw_y+draw_h*0.5-4, Color.white)
      if(Debug) Canvas.rect(draw_x, draw_y, draw_w, draw_h, Color.black)
    } //draw

    update() {

        //handle input
      if(left)  { y = y - speed }
      if(right) { y = y + speed }

        //prevent leaving the screen
      if(y <= 0) y = 0
      if(y >= 1) y = 1

        //handle collision with the ball
      var ball = Game.ball
      var collide = Game.overlap(
        draw_x, draw_y, draw_w, draw_h,
        ball.bound_x, ball.bound_y, ball.bound_w, ball.bound_h)

        //if we collide, we rotate orientations, and 'flow'
      if(collide) {

        Game.paddle0.flow()
        Game.paddle1.flow()

          //note that the bounce is intentionally flipped
          //because we're also flipping orientation, so it feels natural
        if(_orient == Orient.vertical) {
          ball.bounce(1, -1)
        } else {
          ball.bounce(-1, 1)
        }

          //hitting the ball scores you a point!
        _score = _score + 1
          
          //check for end of game
        Game.check_score(this, _score)
      
      } //if collided
      
    } //update

    flow() {

      var orient_was = _orient

      reorient()

      //flow basically rotates the paddles around the edge of the screen.

      //If you change vertical to horizontal below, 
      //it will cycle in a different direction,
      //which creates a different experience. 
      
      //The default is that the opposite player is (bounce RNG willing)
      //on the receiving end of the ball after this. Which is more 
      //like normal pong, where it's back and forth. If swapped, the rotation of the player
      //that hit it, will chase the ball, making for a potential to hog it. 
      //It's interesting both ways!

      if(orient_was == Orient.vertical) {
        if(_which == 0) {
          _which = 1
        } else {
          _which = 0
        }
      }

    } //flow

  } //Paddle

//helpers

  class Lists {
    static find(list, looking_for) {
      var idx = 0
      for(item in list) {
        if(item == looking_for) return idx
        idx = idx + 1
      }
      return -1
    }
  }

  //simple key handler that binds callbacks to key names
  //note there is no unbind, as I didn't need it. 

  class Keys {
    
    construct new(keys) {

      _keys = keys
      _state = {}

      //callbacks
      _down = {}
      _pressed = {}
      _released = {}

    } //new

    check(key) {
      if(Lists.find(_keys, key) == -1) Fiber.abort("invalid key, add it to the list on constructing Keys in Game")
    } //check

    bind_down(key, fn) {
      check(key)
      var fns = _down[key]
      if(!fns) fns = _down[key] = []
      fns.add(fn)
    } //bind_down
    
    bind_pressed(key, fn) {
      check(key)
      var fns = _pressed[key]
      if(!fns) fns = _pressed[key] = []
      fns.add(fn)
    } //bind_pressed
    
    bind_released(key, fn) {
      check(key)
      var fns = _released[key]
      if(!fns) fns = _released[key] = []
      fns.add(fn)
    } //bind_released

    update() {
      _keys.each {|key|

        var prev = _state[key]
        var down = Keyboard.isKeyDown(key)

        _state[key] = down

        if(down && !prev) {
          _state[key] = true
          do(key, _pressed[key])
        } else if(prev && !down) {
          do(key, _released[key])
        } else if(down) {
          do(key, _down[key])
        }

      } //each key
    } //update

      //apply a set of callbacks
    do(key, fns) {
      if(!fns) return
      fns.each {|fn| fn.call() }
    } //do

  } //Keys
