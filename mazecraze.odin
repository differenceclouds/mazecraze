package mazecraze

import "core:log"
import "core:mem"
import "core:c/libc"

import "core:fmt"
import "core:math/rand"
import "core:strings"
import "core:strconv"
import rl "vendor:raylib"


Window :: struct { 
    name:          cstring,
    width:         i32, 
    height:        i32,
    fps:           i32,
    control_flags: rl.ConfigFlags,
}

DEBUG_MEM :: true
TW :: 64
MAZE_WIDTH :: 18
MAZE_HEIGHT :: 12
MAZE_MARGIN :: 8
DRAW_GRID :: false

World :: struct {
    width:   i32,
    height:  i32,
    margin: i32,
    tiles:   []Passage,
    exit: rl.Vector2,
    someone_has_won: bool
}

TileProps :: struct {
    width: f32,
    height: f32,
    inner_width: f32,
    inner_height: f32,
    pad: f32,
    ground_color: rl.Color,
    wall_color: rl.Color,
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
    input: User_Input,
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
    number_of_wins: int,
    win_message: cstring,
}




make_world :: proc(world: ^World, w: i32, h: i32, margin: i32, players: ^[]Player, options: GenerationOptions) {
    // for &tile in world.tiles {
    //     tile = {}
    // }

    world.someone_has_won = false

    // glitch mode!
    // defer delete(world.tiles)

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

    // for n := 0; n < 200; n += 1 {
    for n := 0; n < len(world.tiles) * len(world.tiles); n += 1 {
        if rand.float32() > options.straightaway_factor {
            p = rand.choice_enum(Direction)
        }
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
        if nextX > world.width - 1 {
            nextX -= 1
        }
        if nextX < 0 {
            nextX += 1
        }
        if nextY > world.height - 1 {
            nextY -= 1
        }
        if nextY < 0 {
            nextY += 1
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
    world.exit = {f32(world.width), f32(exitY)}

    //Set Players
    entranceY: f32 = f32(rand.int31_max(world.height))
    for &player, i in players {
        using player
        coord = {0, entranceY}
        position = coord
        prevCoord = coord
    }
}



User_Input :: struct {
    up_pressed: bool,
    down_pressed: bool,
    left_pressed: bool,
    right_pressed: bool,

    up_held: bool,
    down_held: bool,
    left_held: bool,
    right_held: bool,

    reset: bool,
    next_draw_style: bool,
    prev_draw_style: bool
}

Tilemap :: struct {
    texture: rl.Texture2D,
    order: map[Passage]rl.Rectangle
}


Clip :: enum {
    tap,
    tap2,
    wall,
    wall2,
}




DrawStyle :: enum {
    Atari,
    Grayblocks
}

Style : DrawStyle


GenerationOptions :: struct {
    straightaway_factor: f32
}


get_passage_rect :: proc(tileProps: TileProps, dir: Direction) -> rl.Rectangle {
    using tileProps
    switch dir {
        case .North: return {pad, 0, inner_width, pad}
        case .East : return {inner_height + pad, pad, pad, inner_height}
        case .South: return {pad, inner_width + pad, inner_width, pad}
        case .West : return {0, pad, pad, inner_height}
    }
    return {}
}


run_game :: proc(tracking_allocator : mem.Tracking_Allocator) {

    window := Window{"it's the maze-craze", 1280, 768, 60, rl.ConfigFlags{ }}

    rl.ChangeDirectory(rl.GetApplicationDirectory())
    rl.InitWindow(window.width, window.height, window.name)
    rl.SetWindowState( window.control_flags )
    rl.SetTargetFPS(window.fps)
    rl.GuiLoadStyle("style_sunny.rgs")

    rl.InitAudioDevice()

    Style = .Grayblocks


    sounds : [Clip]rl.Sound = {
        .tap = rl.LoadSound("./tap.wav"),
        .tap2 = rl.LoadSound("./tap2.wav"),
        .wall = rl.LoadSound("./wall.wav"),
        .wall2 = rl.LoadSound("./wall2.wav"),
    }


    tilePropsList := [DrawStyle]TileProps {
        .Atari = {
            TW,
            TW,
            TW/2,
            TW/2,
            (TW - TW/2)/2,
            rl.BEIGE,
            rl.DARKGREEN
        },
        .Grayblocks = {
            TW,
            TW,
            28,
            28,
            18,
            rl.DARKGREEN,
            rl.DARKGREEN
        }
    }

    tilemap : Tilemap = {
        rl.LoadTexture("./tilemap_trench_layers.png"),
        make(map[Passage]rl.Rectangle)
    }

    cube := rl.LoadTexture("./cube.png")

    defer delete(tilemap.order)
    tilemap.order[{}] =             {0,0,64,64}
    tilemap.order[{.East}] =        {64,0,64,64}
    tilemap.order[{.East, .West}] = {128,0,64,64}
    tilemap.order[{.West}] =        {192,0,64,64}

    tilemap.order[{.South}] =             {0,64,64,64}
    tilemap.order[{.East, .South}] =        {64,64,64,64}
    tilemap.order[{.East, .South, .West}] = {128,64,64,64}
    tilemap.order[{.South, .West}] =        {192,64,64,64}

    tilemap.order[{.North, .South}] =             {0,128,64,64}
    tilemap.order[{.North, .East, .South}] =        {64,128,64,64}
    tilemap.order[{.North, .East, .South, .West}] = {128,128,64,64}
    tilemap.order[{.North, .South, .West}] =        {192,128,64,64}

    tilemap.order[{.North}] =             {0,192,64,64}
    tilemap.order[{.North, .East}] =        {64,192,64,64}
    tilemap.order[{.North, .East, .West}] = {128,192,64,64}
    tilemap.order[{.North, .West}] =        {192,192,64,64}



    global_input := User_Input {}

    players := make([]Player, 2)
    defer delete(players)

    for &player, i in players {
        using player
        color = PlayerColors[i % len(PlayerColors)]
        speed = 1
        win_message = "0"
    }


    gen_options : GenerationOptions = {.5}

    world := World {
        width = MAZE_WIDTH,
        height = MAZE_HEIGHT,
        tiles = make([]Passage, MAZE_WIDTH * MAZE_HEIGHT)
    }
    make_world(&world, MAZE_WIDTH, MAZE_HEIGHT, MAZE_MARGIN, &players, gen_options)
    defer delete(world.tiles)



    for !rl.WindowShouldClose() {
        process_user_input_global(&global_input)
        process_user_input1(&players[0].input)
        process_user_input2(&players[1].input)


        if global_input.reset {
            make_world(&world, MAZE_WIDTH, MAZE_HEIGHT, MAZE_MARGIN, &players, gen_options)
        }
        if global_input.next_draw_style {
            s := int(Style)
            Style = DrawStyle((s + 1) %% len(DrawStyle))
        }
        if global_input.prev_draw_style {
            s := int(Style)
            Style = DrawStyle((s - 1) %% len(DrawStyle))
        }


        elapsed := rl.GetFrameTime()

        step, wall := update_player(&players[0], elapsed, world, &world.someone_has_won)
        if step {
            rl.PlaySound(sounds[.tap])
        } else if wall {
            // rl.PlaySound(sounds[.wall])
        }

        step2, wall2 := update_player(&players[1], elapsed, world, &world.someone_has_won)
        if step2 {
            rl.PlaySound(sounds[.tap2])
        } else if wall2 {
            // rl.PlaySound(sounds[.wall])
        }

        rl.BeginDrawing() 
        {
            tileProps := tilePropsList[Style]
            using tileProps       

            rl.ClearBackground(ground_color)


            // for player in players {
            //     switch Style {
            //         case .Atari: 
            //             rect: rl.Rectangle = {
            //                 player.position.x * width + pad,
            //                 player.position.y * height + pad,
            //                 inner_width,
            //                 inner_height,
            //             }
            //             rl.DrawRectangleRec(rect, player.color)
            //         case .Grayblocks: 
            //             rl.DrawTextureV(cube, {player.position.x * width, player.position.y * width}, player.color)
            //     }
            // }

            rl.DrawText("G\n\n\n\nO\n\n\n\nA\n\n\n\nL\n\n\n\n", world.width * i32(width) + 48, 250, 64, rl.RAYWHITE)

            w_y:i32=0
            for &player in players {
                rl.DrawText(player.win_message, world.width * i32(width) + 48, 32 + 64 * w_y, 64, player.color)
                w_y += 1
            }

            switch Style {
                case .Atari: {
                    y : f32 = 0
                    x : f32 = 0
                    for tile, i in world.tiles {
                        rl.DrawRectangleRec({x * width, y * height, width, height}, wall_color)

                        centerRect := rl.Rectangle {
                            (x * width) + (width - inner_width)/2,
                            (y * height) + (height - inner_height)/2,
                            inner_width,
                            inner_height
                        }

                        origin := rl.Vector2 {width/2, height/2}
                        rl.DrawRectangleRec(centerRect, ground_color)


                        for dir, rotation in Direction {
                            p := Passage {dir}
                            if p <= tile {
                                rect := get_passage_rect(tileProps, dir)
                                rect.x += x * width
                                rect.y += y * height
                                rl.DrawRectangleRec(rect, ground_color)
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
                    for player in players {
                        rect: rl.Rectangle = {
                            player.position.x * width + pad,
                            player.position.y * height + pad,
                            inner_width,
                            inner_height,
                        }
                        rl.DrawRectangleRec(rect, player.color)
                    }
                }
                case .Grayblocks: {
                    y : f32 = 0
                    x : f32 = 0
                    //Draw walls of maze
                    for tile, i in world.tiles {
                        p := get_passages(i32(x), i32(y), world)

                        rect := tilemap.order[p]
                        rect.x += 256
                        rl.DrawTextureRec(tilemap.texture, rect, {x * width, y * height}, rl.WHITE)
                        if x == f32(world.width - 1) {
                            rect: rl.Rectangle = {0, 128, 32, 64}

                            if Direction.East in p {
                                rect.x = 128 
                            } 
                            rect.x += 256

                            rl.DrawTextureRec(tilemap.texture, rect, {(x + 1) * width, y * height}, rl.WHITE)                                
                        }
                        x += 1
                        if x == f32(world.width) {
                            x = 0
                            y += 1
                        }
                    }

                    //Draw players
                    for player in players {
                        rect : rl.Rectangle = {0,0,64,64}
                        position: rl.Vector2 = {player.position.x * width, player.position.y * height}
                        rl.DrawTextureRec(cube, rect, position, player.color)

                        //Draw sliver of wall over players
                        if player.do_move && (player.coord.x < world.exit.x || player.prevCoord.x < world.exit.x) {
                            switch player.current_direction {
                                case .North:
                                    rl.DrawTextureRec(tilemap.texture, {352, 96, 32, 32}, player.coord * width + 32, rl.WHITE)
                                case .South:
                                    rl.DrawTextureRec(tilemap.texture, {352, 96, 32, 32}, player.prevCoord * width + 32, rl.WHITE)
                                case .East:
                                    rl.DrawTextureRec(tilemap.texture, {384, 128, 32, 32}, player.coord * width, rl.WHITE)
                                case .West:
                                    rl.DrawTextureRec(tilemap.texture, {384, 128, 32, 32}, player.prevCoord * width, rl.WHITE)

                            }
                        }

                    }


                    y = 0
                    x = 0
                    //Draw top of maze
                    for tile, i in world.tiles {
                        p := get_passages(i32(x), i32(y), world)
                        rl.DrawTextureRec(tilemap.texture, tilemap.order[p], {x * width, y * height}, rl.WHITE)
                        if x == f32(world.width - 1) {
                            rect: rl.Rectangle = {0, 128, 32, 64}
                            if Direction.East in p {
                                rect.x = 128
                            } 
                            rl.DrawTextureRec(tilemap.texture, rect, {(x + 1) * width, y * height}, rl.WHITE)                                
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

                    //Draw portion of players above maze
                    for player in players {
                        rect : rl.Rectangle = {0,0,64,64}
                        position: rl.Vector2 = {player.position.x * width, player.position.y * height}
                        for n:f32 = 1; n <= f32(player.number_of_wins); n += 1 {
                            rl.DrawTextureRec(cube, rect, position + {-n * 7, n * 7}, player.color)
                        }

                    }

                    // for player in players {
                    //     rect : rl.Rectangle = {18,18,28,28}
                    //     position: rl.Vector2 = {player.position.x * width + 18, player.position.y * width + 18}
                    //     rl.DrawTextureRec(cube, rect, position, player.color)
                    // }
                }
            }





        }
        rl.EndDrawing()

        when DEBUG_MEM {
            if len(tracking_allocator.bad_free_array) > 0 {
                for b in tracking_allocator.bad_free_array {
                    log.errorf("Bad free at: %v", b.location)
                }

                libc.getchar()
                panic("Bad free detected")
            }
        }

    }
}




main :: proc() {
    tracking_allocator : mem.Tracking_Allocator
    when DEBUG_MEM {
        context.logger = log.create_console_logger()
        default_allocator := context.allocator
        mem.tracking_allocator_init(&tracking_allocator, default_allocator)
        context.allocator = mem.tracking_allocator(&tracking_allocator)
        reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
            err := false

            for _, value in a.allocation_map {
                fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
                err = true
            }

            mem.tracking_allocator_clear(a)
            return err
        }
    }

    run_game(tracking_allocator)

    when DEBUG_MEM {
        if reset_tracking_allocator(&tracking_allocator) {
            libc.getchar()
        }
    }
    mem.tracking_allocator_destroy(&tracking_allocator)


}




