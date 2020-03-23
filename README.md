# pong flow

## A simple pong like game

- Made for [dome jam](https://itch.io/jam/domejam) 
- Made using [dome engine](https://domeengine.com)
- Written in [Wren](http://wren.io)
- Made by [_discovery](https://twitter.com/___discovery/)
- Made in ~3 hours

### Concept

The basic concept is to keep the ball moving. Instead of a miss being 
a failure and a reset (which breaks the game flow), we wrap the ball 
instead of bouncing off walls or failing if missed.

To win, instead of making it failure based, success is used. 
If you hit the ball, you gain a point, and the first to a certain number wins.

Also on the theme of flow, when you do hit the ball, the screen is rotated.
This keeps players on their toes and the game flowing by requiring slightly
faster reflexes and thinking ahead/predicting.

### Running/Editing the game

- Grab the appropriate release from the [releases](https://github.com/underscorediscovery/dome-pong-flow/releases).
- Unzip, and run the dome binary. 
- Note: Linux/Mac: you may need to make the binary executable 

You can also grab your own build of dome from https://github.com/avivbeeri/dome/releases/
