defmodule QuickStructTest do
  use ExUnit.Case


  defmodule User do
    use QuickStruct, fields: [firstname: String.t(), name: String.t()], predicate: :user?
  end

  test "make user struct" do
    assert User.make("Jon", "Adams") == %User{firstname: "Jon", name: "Adams"}
    assert User.make(name: "Adams", firstname: "Jon") == %User{firstname: "Jon", name: "Adams"}
  end

  test "make user struct fails if an additional key is given or a key is missing" do
    assert_raise KeyError,
                 ~r/key :second_name not found in/,
                 fn -> User.make(second_name: "Karl", firstname: "Jon", name: "Adams") end

    assert_raise ArgumentError,
                 ~r/the following keys must also be given.*:firstname/,
                 fn -> User.make(name: "Smith") end
  end

  defmodule Pair do
    use QuickStruct, fields: [:a, :b]
  end

  test "make pair without type specifications" do
    assert Pair.make(1, 2) == %Pair{a: 1, b: 2}
    assert Pair.make("Hello", "World") == %Pair{a: "Hello", b: "World"}
    assert Pair.make(a: [1, 2], b: [3, 4]) == %Pair{a: [1, 2], b: [3, 4]}
  end

  defmodule Single do
    use QuickStruct, fields: [el: String.t()]
  end

  test "make single struct" do
    assert Single.make("Hey") == %Single{el: "Hey"}
  end

  require QuickStruct
  QuickStruct.define_module(SingleKeyword, fields: [val: keyword()])

  test "single keyword list" do
    assert SingleKeyword.make([1, 2, 3]).val == [1, 2, 3]
    assert SingleKeyword.make(val: [1, 2, 3]).val == [1, 2, 3]
  end

  QuickStruct.define_module(Nofields, fields: [])
  ## This is shorthand for:
  # defmodule Nofields do
  #   use QuickStruct, []
  # end

  test "make nofields struct" do
    assert Nofields.make() == %Nofields{}
    assert Nofields.make([]) == %Nofields{}
  end

  test "is struct" do
    u1 = %User{firstname: "Jon", name: "Adams"}
    p1 = %Pair{a: 1, b: 2}
    n1 = %Nofields{}

    map = %{firnstame: "Jon", name: "Adams"}
    lis = [a: 1, b: 2]
    int = 5

    assert User.is_struct(u1)
    refute User.is_struct(p1)
    refute User.is_struct(n1)
    refute User.is_struct(map)
    refute User.is_struct(lis)
    refute User.is_struct(int)

    refute Pair.is_struct(u1)
    assert Pair.is_struct(p1)
    refute Pair.is_struct(n1)
    refute Pair.is_struct(map)
    refute Pair.is_struct(lis)
    refute Pair.is_struct(int)

    refute Nofields.is_struct(u1)
    refute Nofields.is_struct(p1)
    assert Nofields.is_struct(n1)
    refute Nofields.is_struct(map)
    refute Nofields.is_struct(lis)
    refute Nofields.is_struct(int)
  end

   defmodule AreaOrSpace do
     use QuickStruct, fields: [x: float(), y: float(), z: float()]

     QuickStruct.constructor_with_defaults(z: 0)
   end
 
   test "constructor with defaults works" do
     assert AreaOrSpace.make_with_defaults(x: 4, y: -1) == %AreaOrSpace{x: 4, y: -1, z: 0}
     assert AreaOrSpace.make(1, 2, 0) == AreaOrSpace.make_with_defaults(x: 1, y: 2)
   end
 
   test "predicate works" do
     assert User.user?(User.make("Jon", "Adams"))
     refute User.user?(12)
     refute User.user?(AreaOrSpace.make(1, 2, 0))
   end

   doctest QuickStruct
end
