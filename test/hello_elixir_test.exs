defmodule OrderTest do
  use ExUnit.Case

  alias Order.{
    OrderNotOpenException,
    Food,
    OrderStarted,
    FoodOrdered,
    StartOrder,
    OrderFood,
  }

  # Commands

  test StartOrder do
    command = %StartOrder{name: "Zilverline"}
    assert Order.perform(command) == [%OrderStarted{name: "Zilverline"}]
  end

  test OrderFood do
    items = [%Food{name: "Big Belly Burger", quantity: 1, price: 5.15}]
    command = %OrderFood{items: items}
    assert Order.perform(command) == [%FoodOrdered{items: items}]
  end

  # Events

  test OrderStarted do
    events = [%OrderStarted{name: "Zilverline"}]
    order = %Order{} |> Order.replay(events)

    assert order == %Order{name: "Zilverline", open: true, items: []}
  end

  test FoodOrdered do
    items = [%Food{name: "Big Belly Burger", quantity: 1, price: 5.15}]
    events = [%OrderStarted{name: "Zilverline"},
              %FoodOrdered{items: items}]
    order = %Order{} |> Order.replay(events)

    assert order == %Order{name: "Zilverline", open: true, items: items}
  end

  test "FoodOrdered for an order that's not open" do
    items = [%Food{name: "Big Belly Burger", quantity: 1, price: 5.15}]
    events = [%FoodOrdered{items: items}]

    assert_raise OrderNotOpenException, fn ->
      Order.replay(%Order{}, events)
    end
  end
end
