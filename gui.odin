package mazecraze

import rl "vendor:raylib"
import "core:math"








GuiData :: struct {
	unit: f32,
	pad: f32,
	player_setup: bool,

	speed01: i32,
	speed02: i32,

	maze_factor: i32,
}

InitGui :: proc() -> GuiData {
	return {
		unit = 24,
		pad = 4,
		speed01 = 3,
		speed02 = 3,
		maze_factor = 10,
	}
}

UpdateGui :: proc(window: ^Window, data: ^GuiData, players: ^[]Player, maze_options: ^GenerationOptions, input: ^User_Input) {
	using data

	w:f32 = f32(window.width / 2) * 2
	h:f32 = f32(window.height / 2) * 2

	x:f32 = pad
	y:f32 = pad
	r:f32 = w - pad
	b:f32 = h - pad

	if rl.GuiButton({r - unit, b - unit, unit, unit}, "#140#") {
		player_setup = true
	}


	x = 400
	y = 200
	if player_setup {
		if rl.GuiWindowBox({x, y, 600, 256}, "options") == 1 do player_setup = false
		x = x + 8
		y = y + 32
		rl.GuiGroupBox({x, y, 304, 216}, "PLAYER SETUP")

		rl.GuiLabel({x + 16, y + 8, 120, 24}, "player 1 color")
		rl.GuiLabel({x + 168, y + 8, 120, 24}, "player 2 color")
		rl.GuiColorPicker({x + 16, y + 32, 96, 96}, "", &players[0].color)
		rl.GuiColorPicker({x + 168, y + 32, 96, 96}, "", &players[1].color)

		rl.GuiLabel({x + 16, y + 152, 120, 24}, "player 1 speed")
		rl.GuiLabel({x + 168, y + 152, 120, 24}, "player 2 speed")
		rl.GuiSpinner({x + 16, y + 176, 120, 24}, "", &speed01, 1, 10, false)
		rl.GuiSpinner({x + 168, y + 176, 120, 24}, "", &speed02, 1, 10, false)


		players[0].speed = f32(speed01)
		players[1].speed = f32(speed02)

		x = x + 312

		rl.GuiGroupBox({x, y, 152, 216}, "MAZE GENERATION")
		rl.GuiLabel({x + 16, y + 8, 192, 24 }, "corner factor")

		prev_mf := maze_factor
		rl.GuiSpinner({x + 16, y + 32, 120, 24}, "", &maze_factor, 1, 20, false)

		if maze_factor != prev_mf {
			maze_options.straightaway_factor = f32(maze_factor - 1) / 20
		}

		if rl.GuiButton({x + 16, y + 176, 120, 24}, "GENERATE") {
			input.reset = true
		}

		// rl.GuiSlider({x + 312, y + 56, 120, 24}, "", to_cstring(math.round(maze_factor * 10)), &maze_factor, 0, .95)
	}

}












