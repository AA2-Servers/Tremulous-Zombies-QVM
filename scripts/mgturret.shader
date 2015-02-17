models/buildables/mgturret/t_flash
{
	cull disable
	{
		map models/buildables/mgturret/t_flash.tga
		blendfunc add
		rgbGen wave square 0 1 0 10 
	}
}

models/buildables/mgturret/turret_coil
{
	cull disable
	{
		map models/buildables/mgturret/turret_coil.tga
		rgbGen lightingDiffuse
		alphaFunc GE128
	}
}

models/buildables/mgturret/turret_shiny
{
	{
		map models/buildables/mgturret/turret_shiny.tga
		rgbGen lightingDiffuse
	}
	{
		map models/buildables/reactor/reactor_glow.tga
		blendfunc add
		rgbGen wave sin 0 1 0 0.5 
	}
	{
		map models/buildables/mgturret/ref_map.tga
		blendfunc filter
		rgbGen identity
		tcGen environment 
	}
}

