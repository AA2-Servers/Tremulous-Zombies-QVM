models/buildables/dcc/comp_pipes
{
	{
		map models/buildables/dcc/comp_pipes.tga
		rgbGen lightingDiffuse
		//tcGen environment 
	}
	{
		map models/buildables/dcc/comp_pipes_glow.tga
		blendfunc add
		rgbGen wave sin 0 1 0 0.5 
	}
}

models/buildables/dcc/comp_display
{
	{
		map models/buildables/dcc/comp_grad.tga
		rgbGen identity
		tcMod scroll 0 1
	}
	{
		map models/buildables/dcc/comp_display.tga
		blendfunc gl_one gl_src_alpha
		rgbGen identity
	}
}

