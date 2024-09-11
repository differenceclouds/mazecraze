package mazecraze

import glm "core:math/linalg/glsl"
import rl "vendor:raylib"

PlayerColors : []rl.Color = {
    rl.BLUE,
    rl.RED,
    rl.PINK,
    rl.GREEN,
    rl.YELLOW
}

TICK_RATE: f32: 0.1


update_player :: proc(player: ^Player, elapsed: f32, world: World) -> (bool, bool) {
    using player
    // move_timer += elapsed

    if do_move {
        move_timer += elapsed
    }
    if coord != prevCoord {
        p := (move_timer * speed) / (TICK_RATE)
        position.x = glm.lerp_f32(prevCoord.x, coord.x, p)
        position.y = glm.lerp_f32(prevCoord.y, coord.y, p)
    }




    if move_timer >= TICK_RATE / speed {
        do_move = false
        move_timer = 0
        prevCoord = coord
        position = coord 
        up, down, left, right = false, false, false, false

    }

    if input.upHeld {
        up = true
        do_move = true
    }
    if input.downHeld {
        down = true
        do_move = true
    }
    if input.rightHeld {
        right = true
        do_move = true
    } 
    if input.leftHeld {
        left = true
        do_move = true
    }

    step: bool
    wall: bool
    if move_timer == 0 && do_move {
        // move_timer = 0

        passages := get_passages(i32(coord.x), i32(coord.y), world)

        //prioritize changing direction over going straight
        switch current_direction {
            case .North:
                if left && Direction.West in passages {
                    coord.x -= 1
                    current_direction = .West
                } else if right && Direction.East in passages {
                    coord.x += 1
                    current_direction = .East
                } else if down && Direction.South in passages {
                    coord.y += 1
                    current_direction = .South
                } else if up && Direction.North in passages {
                    coord.y -= 1
                    current_direction = .North
                }
            case .East:
                if up && Direction.North in passages {
                    coord.y -= 1
                    current_direction = .North
                } else if down && Direction.South in passages {
                    coord.y += 1
                    current_direction = .South
                } else if left && Direction.West in passages {
                    coord.x -= 1
                    current_direction = .West
                } else if right && Direction.East in passages {
                    coord.x += 1
                    current_direction = .East
                }
            case .South:
                if right && Direction.East in passages {
                    coord.x += 1
                    current_direction = .East
                } else if left && Direction.West in passages {
                    coord.x -= 1
                    current_direction = .West
                } else if up && Direction.North in passages {
                    coord.y -= 1
                    current_direction = .North
                } else if down && Direction.South in passages {
                    coord.y += 1
                    current_direction = .South
                } 
            case .West:
                if down && Direction.South in passages {
                    coord.y += 1
                    current_direction = .South
                } else if up && Direction.North in passages {
                    coord.y -= 1
                    current_direction = .North
                } else if right && Direction.East in passages {
                    coord.x += 1
                    current_direction = .East
                } else if left && Direction.West in passages {
                    coord.x -= 1
                    current_direction = .West
                }
        }

        if coord != prevCoord {
            step = true
            bumped = false
        } else if !bumped {
            bumped = true
            wall = true
        }
    }

    return step, wall
}