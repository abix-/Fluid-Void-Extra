

data:extend({
	{
		type = "recipe",
	    name = "void-pipe",
		energy_required = 4,
		enabled = false,
        ingredients = {
            {type="item", name="pipe", amount=5},
        },
        results = {
            {type="item", name="void-pipe", amount=1},
        }
	},
})

table.insert(data.raw["technology"]["fluid-handling"].effects, {type = "unlock-recipe", recipe = "void-pipe"})