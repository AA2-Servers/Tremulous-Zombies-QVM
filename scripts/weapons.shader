gfx/blaster/orange_particle
{  
  cull disable
  {
    map gfx/blaster/bluex_particle.tga
    blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
    alphaGen vertex
    rgbGen vertex
  }
}

gfx/mdriver/green_particle
{  
  cull disable
  {
    map gfx/mdriver/green_particle.tga
    blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
    rgbGen vertex
    alphaGen vertex
  }
}


gfx/psaw/blue_particle
{  
  cull disable
  {
    map gfx/psaw/blue_particle.jpg
    blendFunc GL_ONE GL_ONE
    alphaGen vertex
    rgbGen vertex
  }
}

gfx/blaster/bluex_particle
{  
  cull disable
  {
    map gfx/blaster/bluex_particle.jpg
    blendFunc GL_ONE GL_ONE
    alphaGen vertex
    rgbGen vertex
  }
}

gfx/blaster/redx_particle
{  
  cull disable
  {
    map gfx/blaster/redx_particle.tga
    blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
    alphaGen vertex
    rgbGen vertex
  }
}

gfx/rifle/verysmallrock
{  
  cull disable
  {
    map gfx/rifle/verysmallrock.tga
    blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
    alphaGen vertex
    rgbGen vertex
  }
}

gfx/prifle/red_blob
{  
  cull disable
  {
    map gfx/prifle/red_blob.tga
    blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
    alphaGen vertex
  }
}

gfx/prifle/red_streak
{  
  cull disable
  {
    map gfx/prifle/red_streak.tga
    blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
    alphaGen vertex
  }
}

gfx/lcannon/primary
{  
   cull disable
   deformVertexes wave sin 0 3 0 0.1
  {
   map gfx/blaster/orange_particle.tga
    blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
    alphaGen vertex
    rgbGen vertex
  }
  {
    animmap 24 gfx/lcannon/primary_1.jpg gfx/lcannon/primary_2.jpg gfx/lcannon/primary_3.jpg gfx/lcannon/primary_4.jpg
    blendFunc GL_ONE GL_ONE
  }
}

gfx/lasgun/purple_particle
{  
  cull disable
  {
    map gfx/lasgun/purple_particle.tga
    blendFunc GL_ONE GL_ONE
  }
}
gfx/laser/laser
{
  cull disable
  {
    map gfx/laser/laser.tga
    blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
    alphaGen vertex
  }
}
models/weapons/rocket/flash
{
  cull none
  {
    map models/weapons/rocket/flash.tga
    blendfunc blend //Transparency
  }
}
models/weapons/rocket/flare
{
  cull none
  {
    map models/weapons/rocket/flare.tga
    blendfunc blend
  }
}
models/weapons/rocket/aleta
{
  cull none
  {
    map models/weapons/rocket/aleta.tga
    blendfunc blend
  }
}
models/weapons/dome/dome
{
        cull none
        {
                map models/weapons/dome/dome.tga
                blendfunc add
    //rgbGen lightingDiffuse
                //rgbGen wave noise 0 1 0 0.02
        }
  {
                map models/weapons/dome/dome_glow.tga
                blendfunc add
                rgbGen wave sin 0 1 0 0.5 
        }
  //{
  //  map models/weapons/dome/dome.tga
  //  blendFunc add
  //  detail
  //  alphaGen lightingSpecular
  //}
  //{
  //  map models/buildables/mgturret/ref_map.jpg
  //  blendFunc GL_DST_COLOR GL_ONE
  //  detail
  //  tcGen environment
  //}
}
gfx/lasergun/laser_particle
{
  cull disable
  {
    map gfx/lasergun/laser_particle.tga
                blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
    rgbGen vertex
    alphaGen vertex
  }
}
models/weapons/machinegun/machinegun
{
  {
    map models/weapons/machinegun/machinegun.jpg
  }
}
models/weapons/shotty/shotty
{
  {
    map models/weapons/shotty/shotty.jpg
  }
}
models/weapons/rocket_launcher/rocket_launcher
{
  {
    map models/weapons/rocket_launcher/rocket_launcher.jpg
  }
}
models/weapons/grenade_launcher/grenade_launcher
{
  {
    map models/weapons/grenade_launcher/grenade_launcher.jpg
  }
}
models/weapons/rocket/rocket
{
  {
    map models/weapons/rocket/rocket.tga
  }
}
models/weapons/lasergun/lasergun
{
  {
    map models/weapons/lasergun/lasergun.jpg
  }
}
