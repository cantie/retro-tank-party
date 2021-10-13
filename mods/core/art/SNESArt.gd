extends "res://src/components/art/BaseArt.gd"

const TANK_COLORS := {
	1: Color("25d9d3"),
	2: Color("9ad72e"),
	3: Color("e41a3c"),
	4: Color("bbc2cd"),
}

const TEAM_COLORS := [
	Color('e41a3c'),
	Color('25d9d3'),
]

func get_tank_color(index: int) -> Color:
	return TANK_COLORS[index]

func get_team_color(index: int) -> Color:
	return TEAM_COLORS[index]
