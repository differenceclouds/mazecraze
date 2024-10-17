package mazecraze

import "core:fmt"
import rl "vendor:raylib"




Laser :: struct {
	position: rl.Vector2,
	direction: Direction,
	state: LaserState,
	state_timer: f32,
	beams: []Beam,
	// beam_index: int
}

LaserState :: enum {
	Scanning,
	Alert,
	Fire
}

Beam :: struct {
	position: rl.Vector2,
	angle: f32,
	state: BeamState,
	state_timer: f32
}

BeamState :: enum {
	Loaded,
	Firing,
	Impact,
	Spent,
}

UpdateLaser :: proc(texture: rl.Texture2D, laser: ^Laser, players: []Player) {
	using laser

    color : rl.Color



    switch laser.state {
    	case .Scanning: {
			color = rl.WHITE
    		for player in players {
    			if player.coord.y == position.y {
    				state = .Alert
    				state_timer = 0
    				// break
    			}
    		}
    	}
    	case .Alert: {
			color = rl.YELLOW
			if state_timer >= 0.5 {
				state = .Fire
				state_timer = 0
				for &beam, i in beams {
					if beam.state == .Loaded || beam.state == .Spent {
						beam.state = .Firing
						fmt.println("beam", i, "firing")
						break
					}
				}
			}
    	}
    	case .Fire: {
    		color = rl.RED
    		if state_timer >= 0.5 {
    			state = .Scanning
    			state_timer = 0
    		}
    	}
    }

    for &beam in beams {
    	UpdateBeam(&beam, laser^)
    }

    rl.DrawTextureV(texture,position * 64 + {-32, 0}, color)
    state_timer += rl.GetFrameTime()
}

UpdateBeam :: proc(beam: ^Beam, laser: Laser) {
	using beam
	switch state {
		case .Loaded, .Spent: 
		case .Firing: {
			if state_timer == 0 {
				position = laser.position
				angle = 180
			}
			v : rl.Vector2 = {-2048, 0}
			v *= state_timer
			p := position * 64 + {0, 32} + v
			rect: rl.Rectangle = {p[0],p[1], 64, 3}
			rl.DrawRectanglePro(rect, {0, 0}, angle, rl.GREEN)

			state_timer += rl.GetFrameTime()

			if p.x < -512 || p.x > 2048 || p.y < -512 || p.y > 2048 {
				state_timer = 0
				state = .Spent
			}
		}
		case .Impact: {
			state_timer += rl.GetFrameTime()
		}
	}

}



