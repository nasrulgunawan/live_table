defmodule LiveTable.Range do
  @moduledoc """
  A module for handling numeric range-based filters in LiveTable.

  This module provides functionality for creating and managing range filters
  for numeric values. It supports creating range sliders with customizable
  options and appearances using Sutra UI's range_slider component.

  ## Options
  The module accepts the following options:
  - `:label` - The label text for the range filter
  - `:unit` - The unit to display after the label (optional)
  - `:min` - Minimum value of the range
  - `:max` - Maximum value of the range
  - `:step` - Step increment (integer for integers, float for decimals)
  - `:default_min` - Default minimum selected value
  - `:default_max` - Default maximum selected value
  - `:pips` - Show scale markers (boolean)
  - `:css_classes` - CSS classes for the main container
  - `:slider_classes` - CSS classes for the slider element
  - `:label_classes` - CSS classes for the label element

  For default values, see: [LiveTable.Range source code](https://github.com/gurujada/live_table/blob/master/lib/live_table/range.ex)

  ## Examples

  ```elixir
  # Creating a numeric range filter with integer step
  Range.new(:price, "price_range", %{
    label: "Price Range",
    unit: "$",
    min: 0,
    max: 1000,
    step: 10
  })

  # Creating a range filter with float step
  Range.new(:rating, "rating_range", %{
    label: "Rating",
    min: 0.0,
    max: 5.0,
    step: 0.5
  })
  ```

  If you want to use the range filter with a joined schema, you can pass the field as a tuple:
  ```elixir
  Range.new({:products, :price}, "price", %{
    label: "Product Price",
    min: 0,
    max: 1000,
  })
  ```
  """

  import Ecto.Query
  use Phoenix.Component
  import LiveTable.TableConfig, only: [deep_merge: 2]

  defstruct [:field, :key, :options]

  @default_options %{
    min: 0,
    max: 100,
    step: 1,
    default_min: 0,
    default_max: 100,
    current_min: nil,
    current_max: nil,
    label: "Range",
    unit: "",
    css_classes: "",
    slider_classes: "w-full",
    label_classes: "block text-sm font-medium leading-6"
  }

  @doc false
  def new(field, key, options) do
    complete_options =
      @default_options
      |> deep_merge(options)

    %__MODULE__{field: field, key: key, options: complete_options}
  end

  @doc false
  def apply(acc, %__MODULE__{field: {table, field}, options: options}) do
    {min_value, max_value} = get_min_max(options)

    dynamic(
      [{^table, t}],
      ^acc and fragment("? BETWEEN ? AND ?", field(t, ^field), ^min_value, ^max_value)
    )
  end

  @doc false
  def apply(acc, %__MODULE__{field: field, options: options}) when is_atom(field) do
    {min_value, max_value} = get_min_max(options)
    dynamic([p], ^acc and fragment("? BETWEEN ? AND ?", field(p, ^field), ^min_value, ^max_value))
  end

  @doc false
  def render(assigns) do
    {current_min, current_max} = get_current_min_max(assigns.applied_filters, assigns.key)

    assigns =
      assigns
      |> Map.put(:current_min, current_min)
      |> Map.put(:current_max, current_max)

    ~H"""
    <div class={@filter.options.css_classes}>
      <label :if={@filter.options.label} class={@filter.options.label_classes}>
        {@filter.options.label}
        <span :if={@filter.options.unit != ""} class="text-base-content/60">
          ({@filter.options.unit})
        </span>
      </label>
      <div class="mt-3 space-y-2">
        <div class="flex items-center gap-2">
          <input
            type="number"
            name={"#{@key}[min]"}
            id={"range_filter_min[#{@key}]"}
            min={@filter.options.min}
            max={@filter.options.max}
            step={@filter.options.step}
            value={@current_min || @filter.options.default_min}
            class="input input-sm w-20"
            placeholder="Min"
            phx-change="range_change"
          />
          <span class="text-base-content/60">to</span>
          <input
            type="number"
            name={"#{@key}[max]"}
            id={"range_filter_max[#{@key}]"}
            min={@filter.options.min}
            max={@filter.options.max}
            step={@filter.options.step}
            value={@current_max || @filter.options.default_max}
            class="input input-sm w-20"
            placeholder="Max"
            phx-change="range_change"
          />
        </div>
        <input
          type="range"
          name={"#{@key}[range]"}
          id={"range_filter[#{@key}]"}
          min={@filter.options.min}
          max={@filter.options.max}
          step={@filter.options.step}
          value={@current_min || @filter.options.default_min}
          class={["range range-sm", @filter.options.slider_classes]}
          phx-change="range_change"
        />
      </div>
    </div>
    """
  end

  defp get_current_min_max(applied_filters, key) do
    case Map.get(applied_filters, key) do
      nil -> {nil, nil}
      %{options: %{current_min: min, current_max: max}} -> {min, max}
    end
  end

  defp get_min_max(options) do
    min = Map.get(options, :current_min) || Map.get(options, :default_min)
    max = Map.get(options, :current_max) || Map.get(options, :default_max)
    {min, max}
  end
end
