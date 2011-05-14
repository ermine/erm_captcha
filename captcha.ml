(*
 * (c) 2011 Anastasia Gornostaeva <ermine@ermine.pp.ru>
 *)

open Freetype2

let font_hres = 300
let font_vres = 300
let font_hor_size = 8 lsl 6
let font_vert_size = 10 lsl 6

let image_width = 140
let image_height = 60

let max_whirl_angle = 0.7

let white = {Color.Rgb.r = 255; g = 255; b = 255; }
let black = {Color.Rgb.r = 0; g = 0; b = 0}

let _ =
  Random.self_init ()
    
let rand_float min max =
  Random.float (max -. min +. 1.0) +. min

let rand_int min max =
  Random.int (max - min + 1) + min


let transform_glyph glyph =
  let () = (* whirl *)
    let matrix = make_rotation
      (if Random.bool () then
          Random.float max_whirl_angle
       else
          -. Random.float max_whirl_angle
      ) in
      glyph_transform glyph matrix
        {x = rand_int 0 50 lsl 6; y = rand_int 0 50 lsl 6} in
  let () = (* vertical size *)
    let matrix = {
      xx = to_fixed_float 1.0;
      xy = 0;
      yx = 0;
      yy = to_fixed_float (rand_float 0.9 1.1);
    } in
      glyph_transform glyph matrix
        {x = rand_int 0 50 lsl 6; y = rand_int 0 50 lsl 6} in
  let () = (* another deformation *)
    if Random.bool () then
      let matrix = {
        xx = to_fixed_float (cos 0.1);
        xy = 0;
        yx = 0;
        yy = to_fixed_float (cos 0.1);
      } in
        glyph_transform glyph matrix {x = 0; y = 0} in
      
  let bbox = glyph_get_cbox glyph FT_GLYPH_BBOX_PIXELS in
    (bbox.xMax - bbox.xMin, bbox.yMax - bbox.yMin)


let draw_black_wave img start_x length height =
  let constant0 =
    if height > image_height then
      float (rand_int (image_height / 2) (height / 2))
    else
      float (rand_int (height / 2) (image_height / 2))
  in
  let constant1 = rand_float 9.0 15.0 in
  let constant2 = Random.float 50.0 in
  let constant3 = Random.float 4.5 in
  let curve_length = float (length - 1) in
  for x = start_x to start_x + length - 1 do
    let y = constant0 +. constant1 *.
      sin (constant2 +. constant3 *. 3.14 *. float x /. curve_length) in
    let yy = truncate y in
      try
        let c = Rgb24.get img x yy in
          if c.Color.Rgb.r = 0 then
            Rgb24.set img x yy white
          else
            Rgb24.set img x yy black
      with _ -> ()
  done

let draw_white_wave img start_x start_y length height =
  let constant0 = float start_y in
  let constant1 = rand_float 5.0 (float (height / 3)) in
  let constant2 = Random.float 50.0 in
  let constant3 = Random.float 4.5 in
  let curve_length = float (length - 1) in
  for x = start_x to start_x + length - 1 do
    let y = constant0 +. constant1 *.
      sin (constant2 +. constant3 *. 3.14 *. float x /. curve_length) in
    let yy = truncate y in
      try
        let c = Rgb24.get img x yy in
          if c.Color.Rgb.r = 0 then (
            Rgb24.set img x yy white;
            Rgb24.set img x (yy+1) white
          )
      with _ -> ()
  done

let draw_char img bitmap_glyph penx =
  let peny =
    if bitmap_glyph.height >= image_height then
      (image_height - bitmap_glyph.height) / 2 + bitmap_glyph.height - 1
    else
      Random.int (image_height - bitmap_glyph.height) + bitmap_glyph.height - 1
  in
    for x = 0 to bitmap_glyph.width - 1 do
      for y = 0 to bitmap_glyph.height - 1 do
        let p = read_bitmap bitmap_glyph.bitmap x y in
          if p > 0 && p < 255 then
            let lx = penx + x
            and ly = peny - y in
              try
                let c = Rgb24.get img lx ly in
                  if c.Color.Rgb.r = 0 then
                    Rgb24.set img lx ly white
                  else
                    Rgb24.set img lx ly black
              with _ -> ()
      done
    done


let draw_string glyphs img width height =
  let string_length, string_height =
    List.fold_left (fun (length, height) g ->
      let w, h = transform_glyph g in
        (length + w, max height h)
    ) (0, 0) glyphs in
  let start_x = (width - string_length) / 2 in
  let rec loop penx = function
    | [] -> ()
    | glyph :: glyphs ->
      let bitmap_glyph = glyph_to_bitmap glyph FT_RENDER_MODE_NORMAL
        {x = 0; y = 0} false in
        draw_char img bitmap_glyph penx;
        let newpenx = penx + bitmap_glyph.width - 1 in
          glyph_done bitmap_glyph.bitmap;
          loop newpenx glyphs
  in
    loop start_x glyphs;

    draw_black_wave img start_x string_length string_height;

    draw_white_wave img start_x (image_height / 2) string_length string_height;
    draw_white_wave img start_x  (image_height / 3) string_length string_height;
    draw_white_wave img start_x (2 * image_height / 3)
      string_length string_height
    

let generate_image face string =
  let len = String.length string in
  let rec get_glyphs acc i =
    if i < len then
      let idx = get_char_index face (Char.code string.[i]) in
        load_glyph face idx [FT_LOAD_DEFAULT];
        let glyph = get_glyph face in
          get_glyphs (glyph :: acc) (succ i)
    else
      List.rev acc
  in
  let glyphs = get_glyphs [] 0 in
  let img = Rgb24.make image_width image_height white in
    draw_string glyphs img image_width image_height;
    List.iter (fun g -> glyph_done g) glyphs;
    img


(* Optimized for arialbd.ttf *)

let get_image string =
  let ft_library = init () in
  let face = new_memory_face ft_library Captcha_font.font 0 in
    set_char_size face font_hor_size font_vert_size font_hres font_vres;
    (* set_pixel_sizes face 40 40; *)
    let img = generate_image face string in
      face_done face;
      freetype_done ft_library;
      img
