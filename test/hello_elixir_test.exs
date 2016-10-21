defmodule OrderTest do
  use ExUnit.Case

  alias Order.{
    OrderNotOpenException,
    OrderHasBalanceException,
    Item,
    OrderStarted,
    FoodOrdered,
    OrderPaid,
    OrderClosed,
    StartOrder,
    OrderFood,
    PayOrder,
    CloseOrder
  }

  # Commands

  test StartOrder do
    command = %StartOrder{name: "Zilverline"}
    assert Order.perform(command) == [%OrderStarted{name: "Zilverline"}]
  end

  test OrderFood do
    items = [%Item{name: "Big Belly Burger", quantity: 1, price: 5.15}]
    command = %OrderFood{items: items}
    assert Order.perform(command) == [%FoodOrdered{items: items}]
  end

  test CloseOrder do
    command = %CloseOrder{}
    assert Order.perform(command) == [%OrderClosed{}]
  end

  test PayOrder do
    command = %PayOrder{amount: 5}
    assert Order.perform(command) == [%OrderPaid{amount: 5}]
  end

  # Events

  test OrderStarted do
    events = [%OrderStarted{name: "Zilverline"}]
    order = %Order{} |> Order.replay(events)

    assert order == %Order{name: "Zilverline", open: true, items: []}
  end

  test FoodOrdered do
    items = [%Item{name: "Big Belly Burger", quantity: 1, price: 5.15},
             %Item{name: "Nuka Cola", quantity: 2, price: 4.20}]
    events = [%OrderStarted{name: "Zilverline"},
              %FoodOrdered{items: items}]
    order = %Order{} |> Order.replay(events)

    assert order == %Order{name: "Zilverline", open: true, items: items, balance: 13.55}
  end

  test "FoodOrdered for an order that's not open" do
    items = [%Item{name: "Big Belly Burger", quantity: 1, price: 5.15}]
    events = [%FoodOrdered{items: items}]

    assert_raise OrderNotOpenException, fn ->
      Order.replay(%Order{}, events)
    end
  end

  test OrderPaid do
    items = [%Item{name: "Big Belly Burger", quantity: 1, price: 5.15}]
    events = [%OrderStarted{name: "Zilverline"},
              %FoodOrdered{items: items},
              %OrderPaid{amount: 5.15}]
    order = %Order{} |> Order.replay(events)

    assert order == %Order{name: "Zilverline", open: true, items: items, balance: 0.0}
  end

  test "OrderPaid amount exceeding balance goes to the tip jar" do
    items = [%Item{name: "Big Belly Burger", quantity: 1, price: 5.15}]
    events = [%OrderStarted{name: "Zilverline"},
              %FoodOrdered{items: items},
              %OrderPaid{amount: 7.0}]
    order = %Order{} |> Order.replay(events)

    assert order == %Order{name: "Zilverline", open: true, items: items, balance: 0.0, tip_jar: 1.8499999999999996}
  end

  test OrderClosed do
    events = [%OrderStarted{name: "Zilverline"},
              %OrderClosed{}]
    order = %Order{} |> Order.replay(events)

    assert order == %Order{name: "Zilverline", open: false, items: []}
  end

  test "OrderClosed for an order that's already closed" do
    events = [%OrderClosed{}]

    assert_raise OrderNotOpenException, fn ->
      %Order{} |> Order.replay(events)
    end
  end

  test "OrderClosed for an order with outstanding balance" do
    items = [%Item{name: "Big Belly Burger", quantity: 1, price: 5.15}]
    events = [%OrderStarted{name: "Zilverline"},
              %FoodOrdered{items: items},
              %OrderPaid{amount: 2.0},
              %OrderClosed{}]

    assert_raise OrderHasBalanceException, fn ->
      %Order{} |> Order.replay(events)
    end
  end
end
