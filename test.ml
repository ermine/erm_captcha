(* Test for memory leak *)

let _ =
  let code = "123456" in
    for i = 0 to 10000000 do
      let img = Captcha.get_image code in
      let data = Png.to_string [] (Images.Rgb24 img) in
        ignore data
    done
    
