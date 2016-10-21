defmodule CQRS.AggregateRoot do
  defmacro __using__(_) do
    quote do
      def replay(aggr, events), do: Enum.reduce(events, aggr, fn(elem, acc) -> __MODULE__.apply(acc, elem) end)
    end
  end
end

defmodule Order do
  defstruct name: "", open: false, items: [], balance: 0.0, tip_jar: 0.0

  use CQRS.AggregateRoot

  # Exceptions

  defmodule OrderNotOpenException, do: defexception message: "Order is not open"
  defmodule OrderHasBalanceException, do: defexception message: "Order has balance and can't be closed"

  # Values

  defmodule Item, do: defstruct name: "", quantity: 1, price: 0.0

  # Events

  defmodule OrderStarted, do: defstruct [:name]
  defmodule FoodOrdered, do: defstruct [:items]
  defmodule OrderPaid, do: defstruct [:amount]
  defmodule OrderClosed, do: defstruct []

  def apply(order, %OrderStarted{name: name}), do: %Order{order | name: name, open: true}

  def apply(%Order{open: false}, _event), do: raise OrderNotOpenException

  def apply(order, %FoodOrdered{items: items}), do: %Order{order | items: items, balance: sum_items(items)}

  def apply(%Order{balance: balance} = order, %OrderPaid{amount: amount}) when amount <= balance do
    %Order{order | balance: order.balance - amount}
  end
  def apply(%Order{balance: balance} = order, %OrderPaid{amount: amount}) when amount > balance do
    %Order{order | balance: 0.0, tip_jar: amount - order.balance}
  end

  def apply(%Order{balance: 0.0} = order, %OrderClosed{}), do: %Order{order | open: false}
  def apply(%Order{}, %OrderClosed{}), do: raise OrderHasBalanceException

  # Commands

  defmodule StartOrder, do: defstruct [:name]
  defmodule OrderFood, do: defstruct [:items]
  defmodule PayOrder, do: defstruct [:amount]
  defmodule CloseOrder, do: defstruct []

  def perform(%StartOrder{name: name}), do: [%OrderStarted{name: name}]
  def perform(%OrderFood{items: items}), do: [%FoodOrdered{items: items}]
  def perform(%PayOrder{amount: amount}), do: [%OrderPaid{amount: amount}]
  def perform(%CloseOrder{}), do: [%OrderClosed{}]

  # Utils

  defp sum_items(items), do: Enum.reduce(items, 0.0, fn(elem, acc) -> acc + (elem.price * elem.quantity) end)
end
