defmodule ToolongWeb.DemoLive do
  use ToolongWeb, :live_view

  # TODO: Accessibility notes:
  #   - font-size should be in rem. https://www.joshwcomeau.com/css/surprising-truth-about-pixels-and-accessibility/
  #   - What should the order of divs in the DOM be?
  #
  # TODO: From frontend, obtain the following info:
  #   - Box heights
  #   - y-offsets for ranges
  def data() do
    ~S"""
    [
      {
          "id": 0,
          "content": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
          "children": [{"id": 1}, {"id": 2}],
          "height": 400
      },
      {
          "id": 1,
          "content": "I don't think what you're saying makes sense. What language is this?",
          "children": [{"id": 3}],
          "parents": [
              {
                  "id": 0,
                  "ranges": [[0, 26], [50, 70]]
              }
          ],
          "height": 100
      },
      {
          "id": 2,
          "content": "I agree with the other comments. What do these words mean?",
          "children": [{"id": 3}],
          "parents": [
              {
                  "id": 0
              }
          ],
          "height": 100
      },
      {
          "id": 3,
          "content": "This is just filler text for testing. It doesn't have any meaning as such.",
          "parents": [
              {
                  "id": 1
              },
              {
                  "id": 2
              }
          ],
          "height": 150
      }
    ]
    """
  end

  def check_valid_prelayout(pre_layout_tuple) do
    Enum.each(0 .. (tuple_size(pre_layout_tuple) - 1),
      fn (i) ->
        if elem(pre_layout_tuple, i)["id"] != i do
          raise "Discussion list index out-of-sync with id in object"
        end
      end)
  end

  @spec compute_layers_recurse(map(), map(), Qex.t()) :: {map(), map()}
  def compute_layers_recurse(id_to_layer, layer_to_ids, todo) do
    case Qex.pop(todo) do
      {:empty, _q} -> {id_to_layer, layer_to_ids}
      {{:value, {id, ps}}, todo} ->
        case Enum.split_with(ps, fn(p_id) -> Map.has_key?(id_to_layer, p_id) end) do
          {done, []} ->
            max_p_layer = done
            |> Enum.map(fn (p_id) -> id_to_layer[p_id] end)
            |> Enum.max()
            new_layer = max_p_layer + 1
            compute_layers_recurse(
              Map.put(id_to_layer, id, new_layer),
              Map.update(layer_to_ids, new_layer, {id},
                fn (old) -> Tuple.append(old, id) end),
              todo
            )
          {_done, remaining} ->
            compute_layers_recurse(id_to_layer, layer_to_ids, Qex.push(todo, {id, remaining}))
        end
    end
  end

  @doc """
  For pre-layout data, compute a mapping of layer_id -> tuple(comment_id)
  """
  @spec compute_layers(tuple()) :: tuple()
  def compute_layers(pre_layout_tuple) do
    # NOTE: The algorithm here is quadratic but that's probably fine?
    {id_to_layer_map, layer_to_ids_map, todo} =
      Enum.reduce(0 .. (tuple_size(pre_layout_tuple) - 1), {%{}, %{}, Qex.new()},
        fn (i, {id_to_layer_map, layer_to_ids_map, worklist}) ->
          elt = elem(pre_layout_tuple, i)
          case Enum.map(Map.get(elt, "parents", []), fn(x) -> x["id"] end) do
            [] -> {
              Map.put(id_to_layer_map, i, 0),
              Map.update(layer_to_ids_map, 0, {i}, fn (old) -> Tuple.append(old, i) end),
              worklist
            }
            ps -> {
              id_to_layer_map,
              layer_to_ids_map,
              Qex.push(worklist, {i, ps})
            }
          end
        end)
    :ok = IO.puts("id-to-layer-map " <> inspect(id_to_layer_map))
    :ok = IO.puts("todo " <> inspect(todo))
    # :ok = IO.puts("layer-to-id-map " <> IO.puts(layer_to_ids_map))
    {_id_to_layers, layer_to_ids} = compute_layers_recurse(id_to_layer_map, layer_to_ids_map, todo)
    layers = layer_to_ids
      |> Map.to_list()
      |> Enum.sort_by(fn (e) -> elem(e, 0) end) # assuming that counting is from 0 to count - 1
      |> Enum.map(fn ({_idx, ids}) -> ids end)
      |> List.to_tuple()
    layers
  end

  def gap() do
    20
  end

  defmodule LayerWithHeight do
    @enforce_keys [:index, :height]
    defstruct [:index, :height]
  end

  @spec find_layer_with_max_height(tuple(), tuple()) :: any
  def find_layer_with_max_height(pre_layout_data, layers) do
    {max_i, max_h} = Enum.reduce(0 .. (tuple_size(layers) - 1), {-1, -1},
      fn (layer_idx, {best_i, best_h}) ->
        layer = elem(layers, layer_idx)
        total_box_heights = Enum.reduce(0 .. (tuple_size(layer) - 1), 0,
          fn (i, acc) ->
            id = elem(layer, i)
            elt = elem(pre_layout_data, id)
            acc + elt["height"]
          end)
        # Account for separations between boxes.
        layer_height = total_box_heights + (tuple_size(layer) - 1) * gap()
        if layer_height > best_h do
          {layer_idx, layer_height}
        else
          {best_i, best_h}
        end
      end)
    %LayerWithHeight{index: max_i, height: max_h}
  end

  def average(enum) do
    {total, count} = Enum.reduce(enum, {0, 0}, fn (elt, {total, count}) ->
        {total + elt, count + 1}
      end)
    total / count
  end

  def set_y(y) do
    fn (data) -> Map.put(data, "y", y) end
  end

  def lowest_y() do
    100
  end

  @doc """
  layer is a tuple containing the ids for a layer, which are keys into the map.
  """
  @spec layout_layer(map(), tuple(), String.t()) :: map()
  def layout_layer(partially_layed_out_map, layer, key) do
    optimal_ys_list = Enum.map(0 .. (tuple_size(layer) - 1), fn (idx) ->
        id = elem(layer, idx)
        elt = partially_layed_out_map[id]
        opt_mid = elt[key]
          |> Enum.map(fn (elt) -> elt["id"] end)
          |> Enum.map(fn (c_i) ->
                side_elt = partially_layed_out_map[c_i]
                side_elt["y"] + (side_elt["height"] / 2)
              end)
          |> average()
        opt_y = opt_mid - elt["height"] / 2
        {id, opt_y}
      end)
    partially_layed_out_map = Enum.reduce(optimal_ys_list, partially_layed_out_map,
      fn({id, opt_y}, m) ->
        Map.update!(m, id, fn (data) -> Map.put(data, "optimal_y", opt_y) end)
      end)
    # Pairs of {id, optimal_y}, sorted by optimal_y
    optimal_ys_sorted = List.to_tuple(Enum.sort_by(optimal_ys_list, fn ({_i, y}) -> y end))
    count = tuple_size(optimal_ys_sorted)
    {partially_layed_out_map, above_idxs, below_idxs} = if rem(count, 2) == 1 do

        mid_idx = trunc(count / 2)
        {id, optimal_y} = elem(optimal_ys_sorted, mid_idx)
        {
          Map.update!(partially_layed_out_map, id, set_y(optimal_y)),
          (mid_idx - 1) .. 0 // -1,
          (mid_idx + 1) .. (count - 1) // 1,
        }
      else
        below_idx = trunc(count / 2)
        above_idx = below_idx - 1
        {above_id, above_optimal_y} = elem(optimal_ys_sorted, above_idx)
        {below_id, below_optimal_y} = elem(optimal_ys_sorted, below_idx)
        m = partially_layed_out_map
        above_bottom = above_optimal_y + m[above_id]["height"]
        below_top = below_optimal_y
        m = if (below_top - above_bottom) > gap() do # No collision
          m
          |> Map.update!(above_id, set_y(above_optimal_y))
          |> Map.update!(below_id, set_y(below_optimal_y))
        else
          needed_y_delta = m[above_id]["height"] + gap()
          current_y_delta = below_optimal_y - above_optimal_y
          offset = (needed_y_delta - current_y_delta) / 2
          m
          |> Map.update!(above_id, set_y(above_optimal_y - offset))
          |> Map.update!(below_id, set_y(below_optimal_y + offset))
        end
        {m, (above_idx - 1) .. 0 // -1, (below_idx + 1) .. (count - 1) // 1}
      end
    m = partially_layed_out_map
    m = Enum.reduce(above_idxs, m, fn (above_idx, m) ->
        {above_id, above_optimal_y} = elem(optimal_ys_sorted, above_idx)
        {below_id, _} = elem(optimal_ys_sorted, above_idx + 1)
        below_y = m[below_id]["y"]
        above_y = if (below_y - above_optimal_y) < gap() do
            below_y - gap() - m[above_id]["height"]
          else
            above_optimal_y
          end
        Map.update!(m, above_id, set_y(above_y))
      end)
    m = Enum.reduce(below_idxs, m, fn(below_idx, m) ->
      {below_id, below_optimal_y} = elem(optimal_ys_sorted, below_idx)
      {above_id, _} = elem(optimal_ys_sorted, below_idx - 1)
      above_y = m[above_id]["y"]
      above_h = m[above_id]["height"]
      below_y = if (below_optimal_y - (above_y + above_h)) < gap() do
          above_y + above_h + gap()
        else
          below_optimal_y
        end
      Map.update!(m, below_id, set_y(below_y))
    end)
    partially_layed_out_map = m
    partially_layed_out_map
  end

  @spec layout_tallest_layer(map(), tuple(), any) :: map()
  def layout_tallest_layer(pre_layout_map, layers, max_h_layer) do
    max_i = max_h_layer.index
    layer = elem(layers, max_i)
    {_, m} = Enum.reduce(0 .. tuple_size(layer) - 1, {lowest_y(), pre_layout_map},
      fn (idx, {cur_y, m}) ->
        id = elem(layer, idx)
        {cur_y + m[id]["height"] + gap(), Map.update!(m, id, set_y(cur_y))}
      end)
    m
  end

  def x_gap() do
    20
  end

  def x_width() do
    200
  end


  @spec compute_layout([any]) :: [any]
  def compute_layout(pre_layout_data) do
    :ok = IO.puts(inspect(pre_layout_data))
    # tuple(pre_layout)
    pre_layout_data = List.to_tuple(pre_layout_data)
    check_valid_prelayout(pre_layout_data)
    layers = compute_layers(pre_layout_data)
    layer_with_max_h = find_layer_with_max_height(pre_layout_data, layers)

    m = Map.new(Tuple.to_list(pre_layout_data), fn (elt) -> {elt["id"], elt} end)
    m = m |> layout_tallest_layer(layers, layer_with_max_h)
    m = Enum.reduce((layer_with_max_h.index - 1) .. 0 // -1, m, fn (i, map) ->
        layout_layer(map, elem(layers, i), "children") # for left side, use children
      end)
    num_layers = tuple_size(layers)
    m = Enum.reduce((layer_with_max_h.index + 1) .. (num_layers - 1) // 1, m, fn (i, map) ->
      layout_layer(map, elem(layers, i), "parents") # for right side, use parents
    end)

    {_final_x, with_xs} = Enum.reduce(0 .. tuple_size(layers) - 1, {0, m}, fn (i, {cur_x, m}) ->
        layer = elem(layers, i)
        m = Enum.reduce(0 .. tuple_size(layer) - 1, m, fn (i, m) ->
            id = elem(layer, i)
            Map.update!(m, id, fn (m) -> Map.put(m, "x", cur_x) end)
          end)
        {cur_x + x_width() + x_gap(), m}
      end)
    Enum.map(0 .. map_size(m) - 1, fn (i) -> with_xs[i] end)
  end

  def mount(_params, _session, socket) do
    # parse JSON into value
    mydata = data()
    {:ok, pre_layout_data} = Jason.decode(mydata)
    new_data = compute_layout(pre_layout_data)
    IO.puts("new data = " <> inspect(new_data))
    socket = assign(socket, :discussion, new_data)
    {:ok, socket}
  end

  def render(assigns) do
    tmp = ~L"""
    <h1>Discussion</h1>
    <%= for comment <- @discussion do %>
    <div style='width: <%= x_width() %>px; height: <%= comment["height"] %>px; position: absolute; top: <%= comment["y"] %>px; left: <%= comment["x"] %>px; border: 1px solid'>
      <%= comment["content"] %>
    </div>
    <% end %>
    """

    tmp
    # ~L"""
    # <h1>Discussion</h1>
    # <div>
    #   Hello World
    # </div>
    # """
  end
end
