#include <stdio.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/custom.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H

#define Library_val(v)            (*((FT_Library **) &Field(v, 0)))
#define Face_val(v)               (*((FT_Face **) &Field(v, 0)))
#define Glyph_val(v)              (*((FT_Glyph **) &Field(v, 0)))
#define Bitmap_val(v)             (*((FT_Bitmap **) &Field(v, 0)))

CAMLprim value ml_init_freetype(value unit) {
  CAMLparam0();
  CAMLlocal1(vres);

  FT_Library *library = caml_stat_alloc(sizeof(FT_Library));
  int error;
  
  error = FT_Init_FreeType(library);
  if(error)
    failwith("cannot init library");

  vres = caml_alloc_small(1, Abstract_tag);
  Library_val(vres) = library;
  
  CAMLreturn(vres);
}

CAMLprim value ml_done_freetype(value library) {
  CAMLparam1(library);

  int error = FT_Done_FreeType(*Library_val(library));
  if (error)
    failwith("FT_Done_Freetype");

  caml_stat_free(Library_val(library));

  CAMLreturn(Val_unit);
}

CAMLprim value ml_new_face(value vlibrary, value vpath, value vface_idx) {
  CAMLparam3(vlibrary, vpath, vface_idx);
  CAMLlocal1(vres);
  int error;
  FT_Face *face = caml_stat_alloc(sizeof(FT_Face));
  
  error = FT_New_Face(*Library_val(vlibrary),
                      String_val(vpath),
                      Long_val(vface_idx), face);
  if(error)
    failwith("cannot new face");

  vres = caml_alloc_small(1, Abstract_tag);
  Face_val(vres) = face;
  CAMLreturn(vres);
}

CAMLprim value ml_new_memory_face(value library, value filebase, 
                                  value face_index) {
  CAMLparam3(library, filebase, face_index);
  CAMLlocal1(vres);

  FT_Face *face = caml_stat_alloc(sizeof(FT_Face));
  int error;

  error = FT_New_Memory_Face(*Library_val(library), Bp_val(filebase), 
                             caml_string_length(filebase),
                             Long_val(face_index), face);
  if(error)
    failwith("FT_New_Memory_Face");

  vres = caml_alloc_small(1, Abstract_tag);
  Face_val(vres) = face;
  CAMLreturn(vres);
}

CAMLprim value ml_done_face(value face) {
  CAMLparam1(face);

  int error = FT_Done_Face(*Face_val(face));
  if(error)
    failwith("FT_Done_Face");

  caml_stat_free(Face_val(face));

  CAMLreturn(Val_unit);
}

CAMLprim value ml_get_char_index(value vface, value vcode) {
  CAMLparam2(vface, vcode);
  FT_UInt ret = FT_Get_Char_Index(*Face_val(vface), Long_val(vcode));
  CAMLreturn(Val_long(ret));
}

CAMLprim value ml_set_char_size(value face, value char_width, value char_height,
                                value hor_res, value vert_res) {
  CAMLparam5(face, char_width, char_height, hor_res, vert_res);
  int error;
  error = FT_Set_Char_Size(*Face_val(face), 
                           Long_val(char_width), Long_val(char_height), 
                           Long_val(hor_res), Long_val(vert_res));
  if(error)
    failwith("FT_Set_Char_Size");

  CAMLreturn(Val_unit);
}

CAMLprim value ml_set_pixel_sizes(value face, value pixel_width, 
                                 value pixel_height) {
  CAMLparam3(face, pixel_width, pixel_height);

  int error = FT_Set_Pixel_Sizes(*Face_val(face), Int_val(pixel_width),
                                 Int_val(pixel_height));
  if(error)
    failwith("FT_Set_Pixel_Size");

  CAMLreturn(Val_unit);
}

static int ml_load_flags[] = {
  FT_LOAD_DEFAULT,
  FT_LOAD_NO_SCALE,
  FT_LOAD_NO_HINTING,
  FT_LOAD_RENDER,
  FT_LOAD_NO_BITMAP,
  FT_LOAD_VERTICAL_LAYOUT,
  FT_LOAD_FORCE_AUTOHINT,
  FT_LOAD_CROP_BITMAP,
  FT_LOAD_PEDANTIC,
  FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH,
  FT_LOAD_NO_RECURSE,
  FT_LOAD_IGNORE_TRANSFORM,
  FT_LOAD_MONOCHROME,
  FT_LOAD_LINEAR_DESIGN,
  FT_LOAD_NO_AUTOHINT
};

CAMLprim value ml_load_char(value face, value char_code, value load_flags) {
  CAMLparam3(face, char_code, load_flags);
  int error;

  error = FT_Load_Char(*Face_val(face), Int_val(char_code),
                       caml_convert_flag_list(load_flags, ml_load_flags));

  if(error)
    failwith("FT_Load_Char");
  CAMLreturn(Val_unit);
}

CAMLprim value ml_load_glyph(value face, value glyph_index, value load_flags) {
  CAMLparam3(face, glyph_index, load_flags);
  int error;

  error = FT_Load_Glyph(*Face_val(face), Long_val(glyph_index),
                        caml_convert_flag_list(load_flags, ml_load_flags));
  
  if(error)
    failwith("FT_Load_Glyph");

  CAMLreturn(Val_unit);
}

CAMLprim value ml_get_glyph(value face) {
  CAMLparam1(face);
  CAMLlocal1(vres);
  FT_Glyph *glyph = caml_stat_alloc(sizeof(FT_Glyph));
  int error;

  error = FT_Get_Glyph((*Face_val(face))->glyph, glyph);
  if(error)
    failwith("FT_Get_Glyph");

  vres = caml_alloc_small(1, Abstract_tag);
  Glyph_val(vres) = glyph;
  CAMLreturn(vres);
}

CAMLprim value ml_set_transform(value face, value vmatrix, value vvec) {
  CAMLparam3(face, vmatrix, vvec);
  FT_Matrix matrix;
  FT_Vector vec;

  matrix.xx = (FT_Fixed)(Long_val(Field(vmatrix,0)));
  matrix.xy = (FT_Fixed)(Long_val(Field(vmatrix,1)));
  matrix.yx = (FT_Fixed)(Long_val(Field(vmatrix,2)));
  matrix.yy = (FT_Fixed)(Long_val(Field(vmatrix,3)));

  vec.x = (FT_Pos)(Long_val(Field(vvec,0)));
  vec.y = (FT_Pos)(Long_val(Field(vvec,1)));

  FT_Set_Transform(*Face_val(face), &matrix, &vec);
  
  CAMLreturn(Val_unit);
}

CAMLprim value ml_glyph_transform(value vglyph, value vmatrix, value vvec) {
  CAMLparam3(vglyph, vmatrix, vvec);

  FT_Matrix matrix;
  FT_Vector vec;

  matrix.xx = (FT_Fixed)(Long_val(Field(vmatrix,0)));
  matrix.xy = (FT_Fixed)(Long_val(Field(vmatrix,1)));
  matrix.yx = (FT_Fixed)(Long_val(Field(vmatrix,2)));
  matrix.yy = (FT_Fixed)(Long_val(Field(vmatrix,3)));

  vec.x = (FT_Pos)(Long_val(Field(vvec,0)));
  vec.y = (FT_Pos)(Long_val(Field(vvec,1)));


  FT_Glyph_Transform(*Glyph_val(vglyph), &matrix, &vec);

  CAMLreturn(Val_unit);
}

CAMLprim value ml_glyph_copy(value glyph) {
  CAMLparam1(glyph);
  CAMLlocal1(vres);
  FT_Glyph *glyph_copy = caml_stat_alloc(sizeof(FT_Glyph));
  int error;

  error = FT_Glyph_Copy(*Glyph_val(glyph), glyph_copy);
  if(error)
    failwith("FT_Glyph_Copy");

  vres = caml_alloc_small(1, Abstract_tag);
  Glyph_val(vres) = glyph_copy;
  CAMLreturn(vres);
}


CAMLprim value ml_glyph_to_bitmap(value glyph, value render_mode, value origin,
                                  value destroy) {
  CAMLparam4(glyph, render_mode, origin, destroy);
  CAMLlocal3(vres, vbitmap, vadvance);
  FT_Glyph image = *Glyph_val(glyph);
  FT_Vector vec;
  int error, mode;

  switch(Int_val(render_mode)) {
  case 0: mode = FT_RENDER_MODE_NORMAL; break;
  case 1: mode = FT_RENDER_MODE_LIGHT; break;
  case 2: mode = FT_RENDER_MODE_MONO; break;
  case 3: mode = FT_RENDER_MODE_LCD; break;
  case 4: mode = FT_RENDER_MODE_LCD_V; break;
  case 5: mode = FT_RENDER_MODE_MAX; break;
  default: failwith("Unknown render node");
  }

  vec.x = (FT_Fixed)(Int_val(Field(origin,0)));
  vec.y = (FT_Fixed)(Int_val(Field(origin,1)));

  error = FT_Glyph_To_Bitmap(&image, mode, &vec, Bool_val(destroy));
  if(error)
    failwith("FT_Glyph_To_Bitmap");
  else {
    FT_BitmapGlyph bit = (FT_BitmapGlyph)image;

    vbitmap = caml_alloc_small(1, Abstract_tag);
    Bitmap_val(vbitmap) = &(bit->bitmap);

    vadvance = caml_alloc_tuple(2);
    Store_field(vadvance, 0, Val_long(bit->root.advance.x));
    Store_field(vadvance, 1, Val_long(bit->root.advance.y));

    vres = caml_alloc_tuple(6);
    Store_field(vres, 0, Val_int(bit->left));
    Store_field(vres, 1, Val_int(bit->top));
    Store_field(vres, 2, Val_int(bit->bitmap.width));
    Store_field(vres, 3, Val_int(bit->bitmap.rows));
    Store_field(vres, 4, vadvance);
    Store_field(vres, 5, vbitmap);

    CAMLreturn(vres);
  }
}

CAMLprim value ml_done_glyph(value glyph) {
  CAMLparam1(glyph);
  
  FT_Done_Glyph(*Glyph_val(glyph));
  caml_stat_free(Glyph_val(glyph));

  CAMLreturn(Val_unit);
}
      
CAMLprim value ml_glyph_get_cbox(value glyph, value bbox_mode) {
  CAMLparam2(glyph, bbox_mode);
  CAMLlocal1(vres);
  FT_BBox bbox;
  int mode = 0;

  switch(Int_val(bbox_mode)) {
  case 0: mode = FT_GLYPH_BBOX_UNSCALED; break;
  case 1: mode = FT_GLYPH_BBOX_SUBPIXELS; break;
  case 2: mode = FT_GLYPH_BBOX_GRIDFIT; break;
  case 3: mode = FT_GLYPH_BBOX_TRUNCATE; break;
  case 4: mode = FT_GLYPH_BBOX_PIXELS; break;
  default: failwith("Unknown bbox mode");
  }

  FT_Glyph_Get_CBox(*Glyph_val(glyph), mode, &bbox);

  vres = caml_alloc_tuple(4);
  Store_field(vres, 0, Val_int(bbox.xMin));
  Store_field(vres, 1, Val_int(bbox.yMin));
  Store_field(vres, 2, Val_int(bbox.xMax));
  Store_field(vres, 3, Val_int(bbox.yMax));
  CAMLreturn(vres);
}

CAMLprim value ml_read_bitmap(value vbitmap, value vx, value vy) {
  CAMLparam3(vbitmap, vx, vy);
  CAMLlocal1(vres);

  FT_Bitmap bitmap = *Bitmap_val(vbitmap);
  unsigned char* row;

  int x = Int_val(vx);
  int y = Int_val(vy);

  if((bitmap.pixel_mode == ft_pixel_mode_grays) ||
     (bitmap.pixel_mode == ft_pixel_mode_mono)) {
    if(bitmap.pitch > 0)
      row = bitmap.buffer + (bitmap.rows - 1 - y) * bitmap.pitch;
    else
      row = bitmap.buffer - y * bitmap.pitch;
  }
  else
    failwith("Unknown bitmap.pixel_mode");
  
  if(bitmap.pixel_mode == ft_pixel_mode_grays)
    CAMLreturn(Val_int(row[x]));
  else
    CAMLreturn(Val_int((row[x >> 3] & (128 >> (x & 7))) ? 255 : 0));
}
  
