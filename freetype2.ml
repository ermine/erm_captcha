type library
type face
type glyph
type bitmap

type vector = {
  x : int;
  y : int
}

type bitmap_glyph = {
  left : int;
  top : int;
  width : int;
  height : int;
  advance : vector;
  bitmap : bitmap
}

type matrix = {
  xx : int;
  xy : int;
  yx : int;
  yy : int
}

external init : unit -> library
  = "ml_init_freetype"
external freetype_done : library -> unit
  = "ml_done_freetype"
external new_face : library -> string -> int -> face
  = "ml_new_face"
external new_memory_face : library -> string -> int -> face
  = "ml_new_memory_face"
external face_done : face -> unit
  = "ml_done_face"
external get_char_index : face -> int -> int
  = "ml_get_char_index"
external set_char_size : face -> int -> int -> int -> int -> unit
  = "ml_set_char_size"

external set_pixel_sizes : face -> int -> int -> unit
  = "ml_set_pixel_sizes"

type load_flag =
  | FT_LOAD_DEFAULT
  | FT_LOAD_NO_SCALE
  | FT_LOAD_NO_HINTING
  | FT_LOAD_RENDER
  | FT_LOAD_NO_BITMAP
  | FT_LOAD_VERTICAL_LAYOUT
  | FT_LOAD_FORCE_AUTOHINT
  | FT_LOAD_CROP_BITMAP
  | FT_LOAD_PEDANTIC
  | FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH
  | FT_LOAD_NO_RECURSE
  | FT_LOAD_IGNORE_TRANSFORM
  | FT_LOAD_MONOCHROME
  | FT_LOAD_LINEAR_DESIGN
  | FT_LOAD_NO_AUTOHINT

external load_char : face -> int -> load_flag list -> unit
  = "ml_load_char"

external load_glyph : face -> int -> load_flag list -> unit
  = "ml_load_glyph"

external get_glyph : face -> glyph
  = "ml_get_glyph"

external set_transform : face -> matrix -> vector -> unit
  = "ml_set_transform"

external glyph_transform : glyph -> matrix -> vector -> unit
  = "ml_glyph_transform"

external glyph_copy : glyph -> glyph
  = "ml_glyph_copy"

type render_mode =
  | FT_RENDER_MODE_NORMAL
  | FT_RENDER_MODE_LIGHT
  | FT_RENDER_MODE_MONO
  | FT_RENDER_MODE_LCD
  | FT_RENDER_MODE_LCD_V
  | FT_RENDER_MODE_MAX

external glyph_to_bitmap : glyph -> render_mode -> vector -> bool -> bitmap_glyph
  = "ml_glyph_to_bitmap"

type bbox = {
  xMin : int;
  yMin : int;
  xMax : int;
  yMax : int
}

type bbox_mode =
  | FT_GLYPH_BBOX_UNSCALED
  | FT_GLYPH_BBOX_SUBPIXELS
  | FT_GLYPH_BBOX_GRIDFIT
  | FT_GLYPH_BBOX_TRUNCATE
  | FT_GLYPH_BBOX_PIXELS
                                                                                
external glyph_get_cbox : glyph -> bbox_mode -> bbox
  = "ml_glyph_get_cbox"

external read_bitmap : bitmap -> int -> int -> int
  = "ml_read_bitmap"

external glyph_done : glyph -> unit
  = "ml_done_glyph"

let to_fixed_float i =
  truncate (i *. float 0x10000)

let make_rotation angle =
  let c = cos angle
  and s = sin angle in
 { xx = to_fixed_float c;
   xy = to_fixed_float (-. s);
   yx = to_fixed_float s;
   yy = to_fixed_float c;
 }
                                                                                
