gfx/mdriver/green_particle
{  
  cull disable
  {
    map gfx/mdriver/green_particle.tga
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		//blendfunc add
	
    //rgbGen vertex
	rgbgen wave sin 1 -0.5 0 1
    alphaGen vertex
  }
}

