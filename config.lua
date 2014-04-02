-- config.lua
application =
{
	content =
	{
		--graphicsCompatibility = 1,  -- This turns on Graphics 1.0 Compatibility mode

        width = 768,
        height = 1024,
        scale = "letterbox",
		antialias = false,
		xalign = "center",
		yalign = "center",

		imageSuffix =
		{
            ["@0-5"] = 0.5, -- for smaller devices
            ["@2x"] = 2,    -- for retina devices
		}
	}
}
