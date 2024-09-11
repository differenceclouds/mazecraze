package mazecraze

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"


Window :: struct { 
    name:          cstring,
    width:         i32, 
    height:        i32,
    fps:           i32,
    control_flags: rl.ConfigFlags,
}

World :: struct {
    width:   i32,
    height:  i32,
    tiles:   []Passage,
    tileProps: TileProps,
    players: []Player
}

TileProps :: struct {
    width: f32,
    height: f32,
    inner_width: f32,
    inner_height: f32,
    pad: f32,
}

GameState :: enum {
    Gameplay,
    Building
}

Direction :: enum {
    North, East, South, West
}

Passage :: bit_set[Direction]


Player :: struct {
    coord: rl.Vector2,
    prevCoord: rl.Vector2,
    position: rl.Vector2,
    color: rl.Color,
    speed: f32,
    move_timer: f32,
    up, down, left, right: bool,
    current_direction: Direction,
    do_move: bool,
    bumped: bool,
}




make_world :: proc(w: i32, h: i32, noPlayers: int) -> World {
    world := World {
        width = w,
        height = h,
        tiles = make([]Passage, w * h),
        tileProps = {64, 64, 32, 32, 16},
        players = make([]Player, noPlayers)
    }


    //Create initial "valid" maze
    x :i32= 0
    y :i32= 0
    for &tile in world.tiles {
        if x < world.width - 1 {
            tile += Passage{.East}
        } else if y < world.height - 1 {
            tile += Passage{.South}
        }

        x += 1
        if x == world.width {
            x = 0
            y += 1
        }
    }

    // Do "Origin Shift" maze generation
    x = world.width - 1
    y = world.height - 1

    p := rand.choice_enum(Direction)

    for n := 0; n < len(world.tiles) * len(world.tiles); n += 1 {
        // if rand.float32() > 0.25 {
            p = rand.choice_enum(Direction)
        // }
        nextX := x
        nextY := y
        switch p {
            case .North:
                nextY -= 1
            case .East:
                nextX += 1
            case .South:
                nextY += 1
            case .West:
                nextX -= 1
        }
        if nextX > world.width - 1 || nextX < 0 || nextY > world.height - 1 || nextY < 0 {
            continue
        }
        world.tiles[y * world.width + x] = Passage{p}
        world.tiles[nextY * world.width + nextX] = {}
        x = nextX
        y = nextY
    }



    // Connect passages
    x = 0
    y = 0
    for &tile, index in world.tiles {

        for dir in Direction {
            p := Passage {dir}
            if p <= tile {
                switch dir {
                    case .North:
                        world.tiles[i32(index) - world.width] += Passage{.South}
                    case .East:
                        world.tiles[i32(index) + 1] += Passage{.West}
                    case .South:
                        world.tiles[i32(index) + world.width] += Passage{.North}
                    case .West:
                        world.tiles[i32(index) - 1] += Passage{.East}
                }
            } 
        }

        x += 1
        if x == world.width {
            x = 0
            y += 1
        }
    }

    //Make Exit
    exitY := rand.int31_max(world.height)
    world.tiles[exitY * world.width + world.width - 1] += Passage{.East}

    //Set Players
    entranceY: f32 = f32(rand.int31_max(world.height))
    for &player, i in world.players {
        using player
        coord = {0, entranceY}
        position = coord
        prevCoord = coord
        color = PlayerColors[i % len(PlayerColors)]
        speed = 1
    }


    return world
}



User_Input :: struct {
    up: bool,
    down: bool,
    left: bool,
    right: bool,

    upHeld: bool,
    downHeld: bool,
    leftHeld: bool,
    rightHeld: bool,

    reset: bool,
}

process_user_input :: proc(user_input: ^User_Input) {
    user_input^ = User_Input {
        up          = rl.IsKeyPressed(.UP),
        down        = rl.IsKeyPressed(.DOWN),
        left        = rl.IsKeyPressed(.LEFT),
        right       = rl.IsKeyPressed(.RIGHT),
        upHeld      = rl.IsKeyDown(.UP),
        downHeld    = rl.IsKeyDown(.DOWN),
        leftHeld    = rl.IsKeyDown(.LEFT),
        rightHeld   = rl.IsKeyDown(.RIGHT),

        reset       = rl.IsKeyPressed(.SPACE),
    }
}


get_passages :: proc(x: i32, y: i32, world: World) -> Passage {
    if x < 0 || x >= world.width || y < 0 || y >= world.height {
        return {.North, .South, .East, .West}
    }
    return world.tiles[y * world.width + x]
}



Clip :: enum {
    tap,
    wall,
    wall2,
}



main :: proc() {
    window := Window{"hyperdongon", 1024, 768, 60, rl.ConfigFlags{ }}

    rl.ChangeDirectory(rl.GetApplicationDirectory())
    rl.InitWindow(window.width, window.height, window.name)
    rl.SetWindowState( window.control_flags )
    rl.SetTargetFPS(window.fps)
    rl.GuiLoadStyle("style_sunny.rgs")

    rl.InitAudioDevice()

    Sounds : [Clip]rl.Sound = {
        .tap = rl.LoadSound("./tap.wav"),
        .wall = rl.LoadSound("./wall.wav"),
        .wall2 = rl.LoadSound("./wall2.wav"),
    }


    user_input : User_Input



    world := make_world(14, 11, 2)

    bgColor := rl.GetColor(0x3F3464FF)
    passageColor := rl.GetColor(0xB2684Aff)


    passageRects := [Direction] rl.Rectangle {
        .North = {16, 0, 32, 16},
        .East = {48, 16, 16, 32},
        .South = {16, 48, 32, 16},
        .West = {0, 16, 16, 32}
    }


    for !rl.WindowShouldClose() {

        process_user_input(&user_input) 

        if user_input.reset {
            world = make_world(14, 11, 2)
        }


        elapsed := rl.GetFrameTime()

        step, wall := update_player(&world.players[0], elapsed, user_input, world)
        if step {
            rl.PlaySound(Sounds[.tap])
        } else if wall {
            rl.PlaySound(Sounds[.wall])
        }

        rl.BeginDrawing() 
        {
            using world.tileProps

            rl.ClearBackground(passageColor)


            y : f32 = 0
            x : f32 = 0
            for tile, i in world.tiles {
                rl.DrawRectangleRec({x * width, y * height, width, height}, bgColor)

                centerRect := rl.Rectangle {
                    (x * width) + (width - inner_width)/2,
                    (y * height) + (height - inner_height)/2,
                    inner_width,
                    inner_height
                }

                origin := rl.Vector2 {width/2, height/2}
                rl.DrawRectangleRec(centerRect, passageColor)


                for dir, rotation in Direction {
                    p := Passage {dir}
                    if p <= tile {
                        rect := passageRects[dir]
                        rect.x += x * width
                        rect.y += y * height
                        rl.DrawRectangleRec(rect, passageColor)
                    }
                }

                if DRAW_GRID {
                    rl.DrawRectangleLinesEx({(x * width), (y * height), width + 1, height + 1}, 1, rl.GRAY)                    
                }


                x += 1
                if x == f32(world.width) {
                    x = 0
                    y += 1
                }

            }

            for player in world.players {
                rect: rl.Rectangle = {
                    player.position.x * width + pad,
                    player.position.y * height + pad,
                    inner_width,
                    inner_height,
                }
                rl.DrawRectangleRec(rect, player.color)
            }
        }
        rl.EndDrawing()

    }
}


DRAW_GRID :: false


