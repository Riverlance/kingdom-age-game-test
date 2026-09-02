DrawCoordFilterShaderFlags = { -- setDrawCoordFilterShaders
  None         = 0,
  _XBR4x       = 2 ^ 0,
  _2xSaILevel2 = 2 ^ 1,
  _2XSaI       = 2 ^ 2,
  Painting     = 2 ^ 3,
}

DrawCoordEffectShaderFlags = { -- setDrawCoordEffectShaders
  None     = 0,
  Heat     = 2 ^ 0,
  Noise    = 2 ^ 1,
  Pal      = 2 ^ 2, -- WARNING! Avoid this shader! It is too heavy!
  Pulse    = 2 ^ 3,
  Water    = 2 ^ 4,
  Zomg     = 2 ^ 5,
}

DrawEffectShaderFlags = { -- setDrawEffectShaders
  None       = 0,
  Grayscale  = 2 ^ 0,
  Negative   = 2 ^ 1,
  Sepia      = 2 ^ 2,
  Party      = 2 ^ 3,
  Bloom      = 2 ^ 4,
  Clouds     = 2 ^ 5,
  Fog        = 2 ^ 6,
  OldTv      = 2 ^ 7,
  RadialBlur = 2 ^ 8,
  Snow       = 2 ^ 9,
}



ShaderUniforms = {
  Progress      = 20,
  ExternalColor = 24,
  InternalColor = 25,
  ContentColor  = 26,
}

MapShaders = {
  { name = 'XBR4x',               antiAliasing = AntiAliasing.disabled, onEnable = function(map, enable) map:setDrawCoordFilterShaders(DrawCoordFilterShaderFlags._XBR4x, enable) end },
  { name = '2xSaI Level 2',       antiAliasing = AntiAliasing.disabled, onEnable = function(map, enable) map:setDrawCoordFilterShaders(DrawCoordFilterShaderFlags._2xSaILevel2, enable) end },
  { name = '2xSaI',               antiAliasing = AntiAliasing.disabled, onEnable = function(map, enable) map:setDrawCoordFilterShaders(DrawCoordFilterShaderFlags._2XSaI, enable) end },
  { name = 'Anti-Aliasing Retro', antiAliasing = AntiAliasing.smoothRetro },
  { name = 'Anti-Aliasing',       antiAliasing = AntiAliasing.enabled },
  { name = 'No Anti-Aliasing',    antiAliasing = AntiAliasing.disabled },
  { name = 'Painting',            antiAliasing = AntiAliasing.smoothRetro, onEnable = function(map, enable) map:setDrawCoordFilterShaders(DrawCoordFilterShaderFlags.Painting, enable) end },
}

OutfitShaders = {
  { name = 'None' }, -- No fragment
  { name = 'Bloom', frag = 'shader/fragment/bloom.frag' },
  { name = 'Bloom Grayscale', frag = 'shader/fragment/bloom.frag', drawColor = false },
  { name = 'Heat', frag = 'shader/fragment/heat.frag' },
  { name = 'Negative', frag = 'shader/fragment/negative.frag' },
  { name = 'Negative Grayscale', frag = 'shader/fragment/negative-grayscale.frag' },
  { name = 'Invisible', frag = 'shader/fragment/negative-grayscale.frag', drawColor = false },
  { name = 'Noise', frag = 'shader/fragment/noise.frag' },
  { name = 'Party', frag = 'shader/fragment/party.frag' },
  { name = 'Radial Blur Grayscale', frag = 'shader/fragment/radialblur.frag', drawColor = false },
  { name = 'Water', frag = 'shader/fragment/water.frag' },
  { name = 'Outline', frag = 'shader/fragment/outline.frag', uniforms = {
    [ShaderUniforms.ExternalColor] = 'u_eColor',
    [ShaderUniforms.InternalColor] = 'u_iColor',
    [ShaderUniforms.ContentColor]  = 'u_cColor',
  } },
}

MountShaders = {
  { name = 'None' }, -- No fragment
  { name = 'Bloom', frag = 'shader/fragment/bloom.frag' },
  { name = 'Negative Grayscale', frag = 'shader/fragment/negative-grayscale.frag' },
  { name = 'Noise', frag = 'shader/fragment/noise.frag' },
  { name = 'Party', frag = 'shader/fragment/party.frag' },
  { name = 'Radial Blur', frag = 'shader/fragment/radialblur.frag' },
}

ItemShaders = {
  { name = 'None' }, -- No fragment
  { name = 'Bloom', frag = 'shader/fragment/bloom.frag' },
  { name = 'Negative Grayscale', frag = 'shader/fragment/negative-grayscale.frag' },
  { name = 'Outline', frag = 'shader/fragment/outline.frag' },
  { name = 'Party', frag = 'shader/fragment/party.frag' },
  { name = 'Radial Blur', frag = 'shader/fragment/radialblur.frag' },
}

WidgetShaders = {
  { name = 'None' }, -- No fragment
  { name = 'Angular', frag = 'shader/fragment/angular.frag', uniforms = { [ShaderUniforms.Progress] = 'u_progress' } },
}

do
  local function registerShader(shaderData, namePrefix, setupCallback)
    local fragmentShaderPath = 'shader/fragment/map-shaders.frag'
    if resolvepath(fragmentShaderPath) then
      local name = f('%s - %s', namePrefix, shaderData.name)
      g_shaders.createFragmentShader(name, fragmentShaderPath) -- Always same fragment file

      -- Texture 1 - Clouds
      g_shaders.addMultiTexture(name, resolvepath('shader/images/clouds'))
      -- Texture 2 - Fog
      g_shaders.addMultiTexture(name, resolvepath('shader/images/fog'))
      -- Texture 3 - Snow
      g_shaders.addMultiTexture(name, resolvepath('shader/images/snow'))

      -- Setup proper uniforms
      g_shaders[setupCallback](name, shaderData.uniforms or { })
    end
  end

  -- Map
  for _, shaderData in ipairs(MapShaders) do
    registerShader(shaderData, 'Map', 'setupMapShader')
  end
end

do
  local name = 'Minimap - Clouds'
  local fragmentShaderPath = 'shader/fragment/clouds.frag'
  if resolvepath(fragmentShaderPath) then
    g_shaders.createFragmentShader(name, fragmentShaderPath)
    g_shaders.addMultiTexture(name, resolvepath('shader/images/minimap_clouds'))
    g_shaders.setupMapShader(name)
  end
end

do
  local function registerShader(shaderData, namePrefix, setupCallback)
    -- local vertexShaderPath = resolvepath(shaderData.frag ~= nil and shaderData.vert or "shader/core/vertex/default.vert")

    if resolvepath(shaderData.frag) then
      local name = f('%s - %s', namePrefix, shaderData.name)
      g_shaders.createFragmentShader(name, shaderData.frag)

      -- Add as many textures you want
      local textureId = 1
      while shaderData['tex' .. textureId] do
        g_shaders.addMultiTexture(name, resolvepath(shaderData['tex' .. textureId]))
        textureId = textureId + 1
      end

      -- Setup proper uniforms
      g_shaders[setupCallback](name, shaderData.uniforms or { })
    end
  end

  -- Outfit
  for _, shaderData in ipairs(OutfitShaders) do
    registerShader(shaderData, 'Outfit', 'setupOutfitShader')
  end

  -- Mount
  for _, shaderData in ipairs(MountShaders) do
    registerShader(shaderData, 'Mount', 'setupMountShader')
  end

  -- Item
  for _, shaderData in ipairs(ItemShaders) do
    registerShader(shaderData, 'Item', 'setupItemShader')
  end

  -- Widget
  for _, shaderData in ipairs(WidgetShaders) do
    registerShader(shaderData, 'Widget', 'setupWidgetShader')
  end
end
