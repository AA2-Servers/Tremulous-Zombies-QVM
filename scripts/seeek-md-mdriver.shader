models/weapons/mdriver/barrelinsidesides
{
	//sort additive
	{
		map models/weapons/mdriver/glow.tga
		//blendFunc add
		tcmod scroll 0 -.1
	}
	{
		map models/weapons/mdriver/barrelinsidesides.tga
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		rgbGen lightingDiffuse
	}
	
}


models/weapons/mdriver/barrelinside
{
	//sort additive
	{
		map models/weapons/mdriver/glow.tga
		//blendFunc add
		tcmod rotate 90
	}
	{
		map models/weapons/mdriver/barrelinside.tga
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		rgbGen lightingDiffuse
	}
	
}

models/weapons/mdriver/barrel_outside
{
	{
		map models/weapons/mdriver/barrel_outside.tga
		rgbGen lightingDiffuse
	}
	
}


models/weapons/mdriver/screen
{
	//sort additive
	{
		map models/weapons/mdriver/screen_content.tga
		//blendFunc add
		//tcmod scroll 0 -.1
	}
	{
		map models/weapons/mdriver/screen_glare.tga
		blendFunc add
		rgbGen lightingDiffuse
		//tcmod scroll 0 -.1
	}
	{
		map models/weapons/mdriver/screen.tga
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		rgbGen lightingDiffuse
	}
	
}


//flashmodelshaders

models/weapons/mdriver/flash
{
	sort additive
	cull disable
	{
		clampmap models/weapons/mdriver/flash.tga
		tcmod rotate 1
	
		blendfunc GL_ONE GL_ONE
	}
}

models/weapons/mdriver/barrelflash
{
	sort additive
	cull disable
	{
		map	models/weapons/mdriver/barrelflash.tga
		blendfunc GL_ONE GL_ONE
	}
}

models/weapons/mdriver/flashsprite
{
	sort additive
	deformvertexes autosprite
	cull disable
	{
		map	models/weapons/mdriver/flashsprite.tga
		blendfunc GL_ONE GL_ONE
	}
}

models/weapons/mdriver/flashinside
{
	sort additive
	cull disable
	{
		map	models/weapons/mdriver/flashinside.tga
		blendfunc GL_ONE GL_ONE
	}
}


