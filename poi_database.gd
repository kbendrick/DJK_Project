extends Node

var poi_dict: Dictionary ={
	"currency_1": {
		"name": "currency",
		"reward": "currency",
		"reward_range": [3,5,7],
		"skill_1": "charisma",
		"skill_2": "perception",
	},
	"currency_2": {
		"name": "currency",
		"reward": "currency",
		"reward_range": [3,5,7],
		"skill_1": "charisma",
		"skill_2": "study",
	},
	"heal_1": {
		"name": "heal",
		"reward": "sanity",
		"reward_range": [1,2,3],
		"skill_1": "medicine",
		"skill_2": "study",
	},
	"heal_2": {
		"name": "heal",
		"reward": "sanity",
		"reward_range": [1,2,3],
		"skill_1": "medicine",
		"skill_2": "cult",
	},
	"mystery_1": {
		"name": "mystery",
		"reward": "mystery",
		"reward_range": ["page", "book", "treasure"],
		"skill_1": "perception",
		"skill_2": "cult",
	},
	"mystery_2": {
		"name": "mystery",
		"reward": "mystery",
		"reward_range": ["page", "book", "treasure"],
		"skill_1": "perception",
		"skill_2": "study",
	},
	"rest_1": {
		"name": "rest",
		"reward": "steps",
		"reward_range": [2, 3, 4],
		"skill_1": "medicine",
		"skill_2": "cult",
	},
	"rest_2": {
		"name": "rest",
		"reward": "steps",
		"reward_range": [2, 3, 4],
		"skill_1": "medicine",
		"skill_2": "perception",
	},
	"upgrade_1": {
		"name": "upgrade",
		"reward": "upgrade",
		"reward_range": [null, null, null],
		"skill_1": "cult",
		"skill_2": "charisma",
	},
	"upgrade_2": {
		"name": "rest",
		"reward": "upgrade",
		"reward_range": [null, null, null],
		"skill_1": "cult",
		"skill_2": "study",
	},
	"hazard_1": {
		"name": "hazard",
		"reward": "steps",
		"reward_range": [2,3,4],
		"skill_1": ["perception", "cult", "study", "medicine", "charisma"],
		"skill_2": ["cult", "study", "medicine", "charisma", "perception"],
	},
	"hazard_2": {
		"name": "hazard",
		"reward": "sanity",
		"reward_range": [2,3,4],
		"skill_1": ["perception", "cult", "study", "medicine", "charisma"],
		"skill_2": ["cult", "study", "medicine", "charisma", "perception"],
	}
}
