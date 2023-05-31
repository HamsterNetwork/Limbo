--region vtable
local vtable = {}

function vtable.entry( instance, index, type )
  return ffi.cast( type, ( ffi.cast( 'void***', instance )[0] )[index] )
end

function vtable.thunk( index, typestring )
  local t = ffi.typeof( typestring )

  return function( instance, ... )
    assert( instance ~= nil )

    if instance then
      return vtable.entry( instance, index, t )( instance, ... )
    end
  end
end

function vtable.bind( module, interface, index, typestring )
  local instance = ffi.cast( 'void*', se.create_interface( module, interface ) ) or error( 'invalid interface' )
  local fnptr = vtable.entry( instance, index, ffi.typeof( typestring ) ) or error( 'invalid vtable' )

  return function( ... )
    return fnptr( instance, ... )
  end
end
--endregion

--region materials
local materials = {}
local materials_mt = {__index = materials}

materials.point = ffi.cast( 'void***', se.create_interface( 'materialsystem.dll', 'VMaterialSystem080' ) )

function materials.add( material )
  return setmetatable( {
    material = material
  }, materials_mt )
end

function materials.set_float_value( material_var, value )
  return vtable.thunk( 3, 'void(__thiscall*)( void*, float )' )( material_var, value )
end

function materials.set_int_value( material_var, value )
  return vtable.thunk( 4, 'void(__thiscall*)( void*, int )' )( material_var, value )
end

function materials.set_string_value( material_var, value )
  return vtable.thunk( 5, 'void(__thiscall*)( void*, const char* )' )( material_var, value )
end

function materials.set_vec_value( material_var, x, y, z )
  return vtable.thunk( 11, 'void(__thiscall*)( void*, float, float, float )' )( material_var, x, y, z )
end

function materials.get( path )
  local material = vtable.thunk( 84, 'void*(__thiscall*)( void*, const char*, const char*, bool, const char* )' )( materials.point, path, '', true, '' )

  return materials.add( material )
end

function materials:get_name( )
  return ffi.string( vtable.thunk( 0, 'const char*(__thiscall*)( void* )' )( self.material ) )
end

function materials:get_texture_group_name( )
  return ffi.string( vtable.thunk( 1, 'const char*(__thiscall*)( void* )' )( self.material ) )
end

function materials:var_flag( flag, value )
  if value == nil then
    return vtable.thunk( 30, 'bool(__thiscall*)( void*, int )' )( self.material, flag )
  end

  vtable.thunk( 29, 'void(__thiscall*)( void*, int, bool )' )( self.material, flag, value )
end

function materials:color_modulate( color )
  if color == nil then
    return
  end

  vtable.thunk( 28, 'void(__thiscall*)( void*, float, float, float )' )( self.material, color.red, color.green, color.blue )
end

function materials:alpha_modulate( alpha )
  if alpha == nil then
    return
  end

  vtable.thunk( 27, 'void(__thiscall*)(void*, float)' )( self.material, alpha/255 )
end

function materials:shader_param( name, ... )
  local args = {...}

  local material_var = vtable.thunk( 11, 'void*(__thiscall*)(void*, const char*, bool, bool)' )( self.material, name, false, true )

  if material_var == nil then
    return
  end

  if #args == 1 then
    if type( args[1] ) == 'string' then
     materials.set_string_value( material_var, args[1] )
    elseif type( args[1] ) == 'number' then
      if string.find( tostring( args[1] ), '.' ) then
        materials.set_float_value( material_var, args[1] )
      else
        materials.set_int_value( material_var, args[1] )
      end
    end
  elseif #args == 3 then
    materials.set_vec_value( material_var, args[1], args[2], args[3] )
  end
end
return materials
--endregion