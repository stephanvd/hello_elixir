defmodule CQRS.AggregateRoot do
  defmacro __using__(_) do
    quote do
      def replay(aggr, events), do: Enum.reduce(events, aggr, fn(elem, acc) -> __MODULE__.apply(acc, elem) end)
    end
  end
end

defmodule Order do
  defstruct name: "", open: false, items: []

  use CQRS.AggregateRoot

  # Exceptions

  defmodule OrderNotOpenException, do: defexception message: "Order is not open"

  # Values

  defmodule Food, do: defstruct name: "", quantity: 1, price: 0.0

  # Events

  defmodule OrderStarted, do: defstruct [:name]
  defmodule FoodOrdered, do: defstruct [:items]

  def apply(order, %OrderStarted{name: name}), do: %Order{order | name: name, open: true}

  def apply(%Order{open: true} = order, %FoodOrdered{items: items}), do: %Order{order | items: items}
  def apply(%Order{open: false}, %FoodOrdered{}), do: raise OrderNotOpenException

  # Commands

  defmodule StartOrder, do: defstruct [:name]
  defmodule OrderFood, do: defstruct [:items]

  def perform(%StartOrder{name: name}), do: [%OrderStarted{name: name}]
  def perform(%OrderFood{items: items}), do: [%FoodOrdered{items: items}]
end
