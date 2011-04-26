open Printf

let pkg_config pkg_name =
  try
    let ic = Unix.open_process_in
      (sprintf "pkg-config --cflags --silence-errors %s" pkg_name) in
    let cflags = input_line ic in
    let ic = Unix.open_process_in
      (sprintf "pkg-config --libs --silence-errors %s" pkg_name) in
    let lflags = input_line ic in
      Some (cflags, lflags)
  with End_of_file ->
    None

(* TODO
let env_cflags = try Some (Sys.getenv "CFLAGS") with Not_foud -> None
let env_libs = try Some (Sys.getenv "LIBS") with Not_found -> None
*)    

let default_dirs =
  ["/usr/include", "/usr/lib";
   "/usr/local/include", "/usr/local/lib"
  ]

let search_in_default_dirs include_file =
  let rec aux_search = function
    | [] -> None
    | (i,l) :: is ->
        if Sys.file_exists (Filename.concat i include_file) then
          Some (("-I" ^ i), ("-L" ^ l))
        else
          aux_search is
  in
    aux_search default_dirs

let check pkg_config_support pkg_name include_file dlflags =
  let cflags, lflags =
    let r =
      if pkg_config_support then
        pkg_config pkg_name
      else
        None
    in
      match r with
        | Some r -> r
        | None ->
            match search_in_default_dirs include_file with
              | Some (i, l) -> (i, l ^ " " ^ dlflags)
              | None ->
                  raise Not_found
  in
    cflags, lflags

let split line ch =
  let rec aux_split acc line =
    let pos =
      try Some (String.index line ch)
    with Not_found -> None in
      match pos with
        | Some pos ->
            aux_split ((String.sub line 0 pos) :: acc)
              (String.sub line (pos+1) (String.length line - pos - 1))
        | None ->
            List.rev (line :: acc)
  in
    aux_split [] line
            
let get_path_gs () =
  let paths = split (Sys.getenv "PATH") ':' in
  let path = List.find (fun path ->
                          Sys.file_exists (Filename.concat path "gs")) paths in
    Filename.concat path "gs"

let var_set name value =
  sprintf "%s=\"%s\"\n" name value

let check_pkg_config () =
  Printf.printf "Checking for pkg-config: ";
  let r =
    try
      let ic = Unix.open_process_in "pkg-config --version" in
      let _line = input_line ic in
        true
    with _ -> false
  in
    Printf.printf "%s\n" (string_of_bool r);
    r
  
let _ =
  let libs =
    [true, "freetype2", "ft2build.h", "-lfreetype"]
  in
  let pkg_config_support = check_pkg_config () in
  let r = List.fold_left
    (fun acc (flag, name, ifile, lf) ->
       if flag then (
         Printf.printf "Checking for %s support... " name;
         let r =
           try
             Some (check pkg_config_support name ifile lf)
           with Not_found -> None
         in
           match r with
             | Some (cflags, lflags) ->
                 Printf.printf
              "\nOptions for library bindings building\ncflags: %s\nlflags: %s\n"
                   cflags lflags;
                 flush stdout;                 
                 (true, name, cflags, lflags) :: acc
             | None ->
                 Printf.printf "no\n";
                 flush stdout;
                 failwith ("Please provide --disable-" ^ name ^
                             " in configure arguments");
                 (*
                 (false, name, "", "") :: acc
                 *)
       )
       else
         acc
    ) [] libs in
  let setupdata = open_out_gen [Open_append; Open_text] 0o644 "setup.data" in
    List.iter (fun (flag, name, cflags, lflags) ->
                 if flag then (
                   output_string setupdata
                     (var_set ("pkg_" ^ name ^ "_cflags") cflags);
                   output_string setupdata
                     (var_set ("pkg_" ^ name ^ "_lflags") lflags);
                 )
              ) r;
    flush setupdata;
    close_out setupdata

