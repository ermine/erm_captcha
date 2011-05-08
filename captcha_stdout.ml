(*
 * (c) 2011 Anastasia Gornostaeva <ermine@ermine.pp.ru>
 *)

let _ =
  let string = Sys.argv.(1) in
  let img = Captcha.get_image string in
    Png.write_image Unix.stdout [] (Images.Rgb24 img);
        
