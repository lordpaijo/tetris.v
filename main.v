module main

import gg
import gx
import time
import rand
import os

// Catppuccin Frappe colors
const bg_color = gx.hex(0x303446)
const surface0 = gx.hex(0x414559)
const surface1 = gx.hex(0x51576d)
const surface2 = gx.hex(0x626880)
const text_color = gx.hex(0xc6d0f5)
const red = gx.hex(0xe78284)
const green = gx.hex(0xa6d189)
const blue = gx.hex(0x8caaee)
const yellow = gx.hex(0xe5c890)
const pink = gx.hex(0xf4b8e4)
const teal = gx.hex(0x81c8be)
const lavender = gx.hex(0xbabbf1)
const overlay0 = gx.hex(0x737994)

// Game constants
const window_width = 640
const window_height = 700
const board_width = 10
const board_height = 20
const block_size = 30
const board_x = 50
const board_y = 50
const sidebar_x = 400
const sidebar_y = 60
const fall_speed = 500 // milliseconds

// Tetromino shapes
const tetrominos = [
	// I piece
	[
		[0, 0, 0, 0],
		[1, 1, 1, 1],
		[0, 0, 0, 0],
		[0, 0, 0, 0]
	],
	// O piece
	[
		[0, 0, 0, 0],
		[0, 1, 1, 0],
		[0, 1, 1, 0],
		[0, 0, 0, 0]
	],
	// T piece
	[
		[0, 0, 0, 0],
		[0, 1, 0, 0],
		[1, 1, 1, 0],
		[0, 0, 0, 0]
	],
	// S piece
	[
		[0, 0, 0, 0],
		[0, 1, 1, 0],
		[1, 1, 0, 0],
		[0, 0, 0, 0]
	],
	// Z piece
	[
		[0, 0, 0, 0],
		[1, 1, 0, 0],
		[0, 1, 1, 0],
		[0, 0, 0, 0]
	],
	// J piece
	[
		[0, 0, 0, 0],
		[1, 0, 0, 0],
		[1, 1, 1, 0],
		[0, 0, 0, 0]
	],
	// L piece
	[
		[0, 0, 0, 0],
		[0, 0, 1, 0],
		[1, 1, 1, 0],
		[0, 0, 0, 0]
	]
]

const tetromino_colors = [blue, yellow, pink, green, red, teal, lavender]

struct Tetromino {
mut:
	shape [][]int
	x int
	y int
	color gx.Color
}

struct Game {
mut:
	gg &gg.Context = unsafe { nil }
	board [][]int
	current_piece Tetromino
	next_piece Tetromino
	score int
	highscore int
	last_fall time.Time
	game_over bool
}

fn main() {
	mut game := &Game{
		board: [][]int{len: board_height, init: []int{len: board_width}}
		score: 0
		highscore: load_highscore()
		last_fall: time.now()
		game_over: false
	}
	
	game.spawn_piece()
	game.generate_next_piece()
	
	game.gg = gg.new_context(
		bg_color: bg_color
		width: window_width
		height: window_height
		window_title: 'Tetris in Vlang by Lordpaijo'
		user_data: game
		frame_fn: frame
		event_fn: event
	)
	
	game.gg.run()
}

fn load_highscore() int {
	content := os.read_file('highscore.txt') or { return 0 }
	return content.int()
}

fn save_highscore(score int) {
	os.write_file('highscore.txt', score.str()) or { }
}

fn (mut game Game) spawn_piece() {
	piece_type := rand.int_in_range(0, tetrominos.len) or { 0 }
	game.current_piece = Tetromino{
		shape: tetrominos[piece_type].clone()
		x: board_width / 2 - 2
		y: 0
		color: tetromino_colors[piece_type]
	}
}

fn (mut game Game) generate_next_piece() {
	piece_type := rand.int_in_range(0, tetrominos.len) or { 0 }
	game.next_piece = Tetromino{
		shape: tetrominos[piece_type].clone()
		x: 0
		y: 0
		color: tetromino_colors[piece_type]
	}
}

fn (mut game Game) can_move(dx int, dy int, shape [][]int) bool {
	for y in 0..4 {
		for x in 0..4 {
			if shape[y][x] != 0 {
				new_x := game.current_piece.x + x + dx
				new_y := game.current_piece.y + y + dy
				
				if new_x < 0 || new_x >= board_width || new_y >= board_height {
					return false
				}
				
				if new_y >= 0 && game.board[new_y][new_x] != 0 {
					return false
				}
			}
		}
	}
	return true
}

fn (mut game Game) place_piece() {
	for y in 0..4 {
		for x in 0..4 {
			if game.current_piece.shape[y][x] != 0 {
				piece_x := game.current_piece.x + x
				piece_y := game.current_piece.y + y
				if piece_y >= 0 {
					game.board[piece_y][piece_x] = 1
				}
			}
		}
	}
	
	game.clear_lines()
	game.current_piece = game.next_piece
	game.current_piece.x = board_width / 2 - 2
	game.current_piece.y = 0
	game.generate_next_piece()
	
	if !game.can_move(0, 0, game.current_piece.shape) {
		game.game_over = true
		if game.score > game.highscore {
			game.highscore = game.score
			save_highscore(game.highscore)
		}
	}
}

fn (mut game Game) clear_lines() {
	mut lines_cleared := 0
	
	for y := board_height - 1; y >= 0; y-- {
		mut full := true
		for x in 0..board_width {
			if game.board[y][x] == 0 {
				full = false
				break
			}
		}
		
		if full {
			// Remove the line
			for move_y := y; move_y > 0; move_y-- {
				for x in 0..board_width {
					game.board[move_y][x] = game.board[move_y - 1][x]
				}
			}
			// Clear top line
			for x in 0..board_width {
				game.board[0][x] = 0
			}
			lines_cleared++
			y++ // Check the same line again
		}
	}
	
	// Update score
	match lines_cleared {
		1 { game.score += 100 }
		2 { game.score += 300 }
		3 { game.score += 500 }
		4 { game.score += 800 }
		else {}
	}
}

fn rotate_piece(shape [][]int) [][]int {
	mut rotated := [][]int{len: 4, init: []int{len: 4}}
	for y in 0..4 {
		for x in 0..4 {
			rotated[x][3-y] = shape[y][x]
		}
	}
	return rotated
}

fn frame(mut game Game) {
	game.gg.begin()
	
	if !game.game_over {
		// Handle falling
		now := time.now()
		if now - game.last_fall > time.millisecond * fall_speed {
			if game.can_move(0, 1, game.current_piece.shape) {
				game.current_piece.y++
			} else {
				game.place_piece()
			}
			game.last_fall = now
		}
	}
	
	// Draw board background
	game.gg.draw_rect_filled(board_x - 5, board_y - 5, 
		board_width * block_size + 10, board_height * block_size + 10, surface0)
	
	// Draw grid
	for y in 0..board_height + 1 {
		game.gg.draw_line(board_x, board_y + y * block_size,
			board_x + board_width * block_size, board_y + y * block_size, overlay0)
	}
	for x in 0..board_width + 1 {
		game.gg.draw_line(board_x + x * block_size, board_y,
			board_x + x * block_size, board_y + board_height * block_size, overlay0)
	}
	
	// Draw placed blocks
	for y in 0..board_height {
		for x in 0..board_width {
			if game.board[y][x] != 0 {
				game.gg.draw_rect_filled(board_x + x * block_size + 1,
					board_y + y * block_size + 1,
					block_size - 2, block_size - 2, surface1)
			}
		}
	}
	
	// Draw current piece
	if !game.game_over {
		for y in 0..4 {
			for x in 0..4 {
				if game.current_piece.shape[y][x] != 0 {
					draw_x := board_x + (game.current_piece.x + x) * block_size + 1
					draw_y := board_y + (game.current_piece.y + y) * block_size + 1
					if draw_y >= board_y {
						game.gg.draw_rect_filled(draw_x, draw_y,
							block_size - 2, block_size - 2, game.current_piece.color)
					}
				}
			}
		}
	}
	
	// Draw sidebar
	game.gg.draw_rect_filled(sidebar_x - 10, sidebar_y - 10, 200, 600, surface0)
	
	// Draw next piece
	game.gg.draw_text(sidebar_x, sidebar_y, 'Next:', gx.TextCfg{
		color: text_color
		size: 30
	})
	
	for y in 0..4 {
		for x in 0..4 {
			if game.next_piece.shape[y][x] != 0 {
				game.gg.draw_rect_filled(sidebar_x + x * 20 + 10,
					sidebar_y + y * 20 + 30,
					18, 18, game.next_piece.color)
			}
		}
	}
	
	// Draw score
	game.gg.draw_text(sidebar_x, sidebar_y + 150, 'Score:', gx.TextCfg{
		color: text_color
		size: 30
	})
	game.gg.draw_text(sidebar_x, sidebar_y + 180, '${game.score}', gx.TextCfg{
		color: green
		size: 34
	})
	
	// Draw highscore
	game.gg.draw_text(sidebar_x, sidebar_y + 220, 'Highscore:', gx.TextCfg{
		color: text_color
		size: 30
	})
	game.gg.draw_text(sidebar_x, sidebar_y + 250, '${game.highscore}', gx.TextCfg{
		color: yellow
		size: 34
	})
	
	// Draw github credit
	game.gg.draw_text(sidebar_x, sidebar_y + 350, 'github.com/lordpaijo', gx.TextCfg{
		color: lavender
		size: 20
	})
	
	// Draw controls
	game.gg.draw_text(sidebar_x, sidebar_y + 400, 'Controls:', gx.TextCfg{
		color: text_color
		size: 28
	})
	game.gg.draw_text(sidebar_x, sidebar_y + 430, 'A/D - Move', gx.TextCfg{
		color: overlay0
		size: 24
	})
	game.gg.draw_text(sidebar_x, sidebar_y + 450, 'S - Soft drop', gx.TextCfg{
		color: overlay0
		size: 24
	})
	game.gg.draw_text(sidebar_x, sidebar_y + 470, 'W - Rotate', gx.TextCfg{
		color: overlay0
		size: 24
	})
	game.gg.draw_text(sidebar_x, sidebar_y + 490, 'R - Restart', gx.TextCfg{
		color: overlay0
		size: 24
	})
	
	// Draw game over screen
	if game.game_over {
		game.gg.draw_rect_filled(board_x, board_y + board_height * block_size / 2 - 50,
			board_width * block_size, 100, surface2)
		game.gg.draw_text(board_x + 50, board_y + board_height * block_size / 2 - 20,
			'GAME OVER', gx.TextCfg{
			color: red
			size: 32
		})
		game.gg.draw_text(board_x + 50, board_y + board_height * block_size / 2 + 10,
			'Press R to restart', gx.TextCfg{
			color: text_color
			size: 28
		})
	}
	
	game.gg.end()
}

fn event(e &gg.Event, mut game Game) {
	match e.typ {
		.key_down {
			match e.key_code {
				.a {
					if game.can_move(-1, 0, game.current_piece.shape) {
						game.current_piece.x--
					}
				}
				.d {
					if game.can_move(1, 0, game.current_piece.shape) {
						game.current_piece.x++
					}
				}
				.s {
					if game.can_move(0, 1, game.current_piece.shape) {
						game.current_piece.y++
						game.score++
					}
				}
				.w {
					rotated := rotate_piece(game.current_piece.shape)
					if game.can_move(0, 0, rotated) {
						game.current_piece.shape = rotated
					}
				}
				.r {
					if game.game_over {
						// Restart game
						game.board = [][]int{len: board_height, init: []int{len: board_width}}
						game.score = 0
						game.game_over = false
						game.spawn_piece()
						game.generate_next_piece()
						game.last_fall = time.now()
					}
				}
				.escape {
					game.gg.quit()
				}
				else {}
			}
		}
		else {}
	}
}