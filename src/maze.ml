open! Core

(* module Index_Key = struct type t = int * int end *)

(* Get the current direction of a tuple *)
let return_direction ~x_move ~y_move =
  match x_move, y_move with
  | -1, 0 -> "Left"
  | 1, 0 -> "Right"
  | 0, 1 -> "Down"
  | 0, -1 -> "Up"
  | _ -> assert false
;;

(* Get the neighbors of a certain cell in a position *)
let get_neighbors ~curr_x ~curr_y ~maze_grid ~num_rows ~num_cols =
  let neighbor_pos = [ -1, 0; 0, 1; 0, -1; 1, 0 ] in
  let neighbors =
    List.fold neighbor_pos ~init:[] ~f:(fun acc (x_move, y_move) ->
      if curr_x + x_move < num_cols
         && curr_x + x_move >= 0
         && curr_y + y_move > 0
         && curr_y + y_move < num_rows
      then (
        let neighbor =
          Array.get (Array.get maze_grid (curr_y + y_move)) (curr_x + x_move)
        in
        if Char.equal neighbor '.' || Char.equal neighbor 'E'
        then (
          let dir = return_direction ~x_move ~y_move in
          let neighbor =
            string_of_int (curr_x + x_move)
            ^ ","
            ^ string_of_int (curr_y + y_move - 1)
          in
          (neighbor, dir) :: acc)
        else acc)
      else acc)
  in
  List.fold neighbors ~init:String.Map.empty ~f:(fun acc (neighbor, dir) ->
    Map.add_exn acc ~key:neighbor ~data:dir)
;;

let rec dfs
  ~(maze : string Core.String.Map.t Core.String.Map.t)
  ~(curr_pos : string)
  ~(end_pos : string)
  ~(visited : String.Set.t)
  ~(visited_list : string list)
  =
  let visited = Set.add visited curr_pos in
  let neighbors = Map.find maze curr_pos in
  match neighbors with
  | None -> None
  | Some neighbors ->
    Map.fold_until
      neighbors
      ~init:visited_list
      ~f:(fun ~key:curr_neighbor_pos ~data:dir acc ->
        if String.equal curr_neighbor_pos end_pos
        then (
          print_endline "finished";
          Continue_or_stop.Stop (Some (visited_list @ [ dir ])))
        else if not (Set.mem visited curr_neighbor_pos)
        then (
          let current_prog =
            dfs
              ~maze
              ~curr_pos:curr_neighbor_pos
              ~end_pos
              ~visited
              ~visited_list:(visited_list @ [ dir ])
          in
          match current_prog with
          | Some list -> Stop (Some list)
          | None -> Continue acc)
        else Continue acc)
      ~finish:(fun _acc -> None)
;;

(* let to_return = [] in if (curr_x - 1 >= 0) then let left_char = (Array.get
   maze_grid (curr_x - 1) curr_y) in if (Char.equal left_char '.' ||
   Char.equal left_char 'E') then (left_char, "left") :: to_return

   in to_return *)

let solve file =
  let file_list = In_channel.read_lines (File_path.to_string file) in
  let array =
    List.fold file_list ~init:[ [] ] ~f:(fun acc curr_row ->
      acc @ [ String.to_list curr_row ])
  in
  let array =
    Array.of_list (List.map array ~f:(fun element -> Array.of_list element))
  in
  let num_rows = Array.length array - 1 in
  let graph = String.Map.empty in
  let final_graph =
    Array.foldi array ~init:graph ~f:(fun y graph row ->
      if not (Array.is_empty row)
      then (
        let num_cols = Array.length row in
        Array.foldi row ~init:graph ~f:(fun x acc char_element ->
          if Char.equal char_element '.' || Char.equal char_element 'S'
          then (
            let neighbors =
              get_neighbors
                ~curr_x:x
                ~curr_y:y
                ~maze_grid:array
                ~num_rows
                ~num_cols
            in
            let key = string_of_int x ^ "," ^ string_of_int (y - 1) in
            Map.add_exn acc ~key ~data:neighbors)
          else acc))
      else graph)
  in
  let () =
    print_s
      [%message (final_graph : string Core.String.Map.t Core.String.Map.t)]
  in
  let start_m, end_m =
    Array.foldi array ~init:("0,0", "0,0") ~f:(fun y (start, end_m) row ->
      Array.foldi
        row
        ~init:(start, end_m)
        ~f:(fun x (m_start, m_end) char_element ->
        let s =
          if Char.equal char_element 'S'
          then string_of_int x ^ "," ^ string_of_int (y - 1)
          else m_start
        in
        let e =
          if Char.equal char_element 'E'
          then string_of_int x ^ "," ^ string_of_int (y - 1)
          else m_end
        in
        s, e))
  in
  let list =
    dfs
      ~maze:final_graph
      ~curr_pos:start_m
      ~end_pos:end_m
      ~visited:String.Set.empty
      ~visited_list:[]
  in
  match list with
  | None -> print_s [%message "lose"]
  | Some list ->
    print_s [%message "Directions to Win: " (list : string list)]
;;

let solve_command =
  let open Command.Let_syntax in
  Command.basic
    ~summary:"parse a file containing a maze and find a solution"
    [%map_open
      let input_file =
        flag
          "input"
          (required File_path.arg_type)
          ~doc:"FILE a file containing a maze"
      in
      fun () -> solve input_file]
;;

let command =
  Command.group ~summary:"maze commands" [ "solve", solve_command ]
;;
