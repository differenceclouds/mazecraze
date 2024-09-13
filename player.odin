package mazecraze

import "core:fmt"
import rl "vendor:raylib"
import math "core:math"
import "core:strings"
import "core:strconv"

PlayerColors : []rl.Color = {
    rl.BLUE,
    rl.RED,
    rl.PINK,
    rl.GREEN,
    rl.YELLOW
}

TICK_RATE: f32: 0.15


process_user_input_global :: proc(user_input: ^User_Input) {
    user_input^ = User_Input {
        reset       = rl.IsKeyPressed(.SPACE),
        next_draw_style = rl.IsKeyPressed(.RIGHT_BRACKET),
        prev_draw_style = rl.IsKeyPressed(.LEFT_BRACKET)
    }
}

process_user_input1 :: proc(user_input: ^User_Input) {
    user_input^ = User_Input {
        up_pressed          = rl.IsKeyPressed(.UP),
        down_pressed        = rl.IsKeyPressed(.DOWN),
        left_pressed        = rl.IsKeyPressed(.LEFT),
        right_pressed       = rl.IsKeyPressed(.RIGHT),
        up_held             = rl.IsKeyDown(.UP),
        down_held           = rl.IsKeyDown(.DOWN),
        left_held           = rl.IsKeyDown(.LEFT),
        right_held          = rl.IsKeyDown(.RIGHT),
        // reset       = rl.IsKeyPressed(.SPACE),
    }
}

process_user_input2 :: proc(user_input: ^User_Input) {
    user_input^ = User_Input {
        up_pressed          = rl.IsKeyPressed(.W),
        down_pressed        = rl.IsKeyPressed(.S),
        left_pressed        = rl.IsKeyPressed(.A),
        right_pressed       = rl.IsKeyPressed(.D),
        up_held             = rl.IsKeyDown(.W),
        down_held           = rl.IsKeyDown(.S),
        left_held           = rl.IsKeyDown(.A),
        right_held          = rl.IsKeyDown(.D),
        // reset       = rl.IsKeyPressed(.SPACE),
    }
}

get_passages :: proc(x: i32, y: i32, world: World) -> Passage {
    if x < 0 || x >= world.width || y < 0 || y >= world.height {
        return {.North, .South, .East, .West}
    }
    return world.tiles[y * world.width + x]
}



update_player :: proc(player: ^Player, elapsed: f32, world: World, someone_has_won: ^bool) -> (bool, bool) {
    using player

    if do_move {
        move_timer += elapsed
    }
    if coord != prevCoord {
        p := (move_timer * speed) / (TICK_RATE)
        position = math.lerp(prevCoord, coord, p)
    }

    if move_timer >= TICK_RATE / speed {
        do_move = false
        move_timer = 0
        prevCoord = coord
        position = coord 
        up, down, left, right = false, false, false, false

    }

    if input.up_held {
        up = true
        do_move = true
    }
    if input.down_held {
        down = true
        do_move = true
    }
    if input.right_held {
        right = true
        do_move = true
    } 
    if input.left_held {
        left = true
        do_move = true
    }

    step: bool
    wall: bool
    if move_timer == 0 && do_move {
        //prioritize changing direction over going straight
        //      change to array of directions with other enum array good stuff??
        //      case .North: check_order = {.West, .East, .South, .North}
        //      case .East: check_order = {.North, .South, .West, .East}
        passages := get_passages(i32(coord.x), i32(coord.y), world)



        if coord.x == f32(world.width) && coord.y != world.exit.y {
            passages = {.North, .East, .South}
        }

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

        if coord == world.exit && !someone_has_won^ {
            // buf: [64]u8 = ---

            number_of_wins += 1
            someone_has_won^ = true

            player.win_message = to_cstring(number_of_wins)  
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