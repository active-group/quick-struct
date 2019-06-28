# QuickStruct [![Build Status](https://travis-ci.org/active-group/quick-struct.svg?branch=master)](https://travis-ci.org/active-group/quick-struct)

Macro to create data structures as structs with less boilerplate.

## Installation

First, add QuickStruct to your `mix.exs` dependencies:

```elixir
def deps do
  [{:quick_struct, "~> 0.1"}]
end
```

and run `$ mix deps.get`.

## Usage

```elixir
defmodule User do
  use QuickStruct, [firstname: String.t, name: String.t]
end
```

Now you can use `User.t` in `@type` and `@spec` declarations. To create
instances of your data structure, use one of the following options:
```elixir
iex(3)> User.make("Jon", "Adams")
%User{firstname: "Jon", name: "Adams"}
iex(4)> User.make([name: "Adams", firstname: "Jon"])
%User{firstname: "Jon", name: "Adams"}
iex(5)> %User{name: "Adams", firstname: "Jon"}
%User{firstname: "Jon", name: "Adams"}
```

You can also define a struct without types, for instance:
```elixir
defmodule QuickStructTest.Pair do
  use QuickStruct, [:first, :second]
end
```

### Resulting code

The QuickStruct macro is a very shorthand option to define a struct, a
data type and enforce all fields. The `User`-struct is equivalent to:
```elixir
@enforce_keys [:firstname, :name]
defstruct [:firstname, :name]
@type t :: %User{firstname: String.t, name: String.t}
```

The macro also provides `make`-functions as constructors and other functions, see [QuickStruct](https://hexdocs.pm/quick_struct/QuickStruct.html) for further documentation. The generated `make`-functions for the `User`-struct are equivalent to:
```elixir
@spec make(String.t, String.t) :: User.t
def make(firstname, name) do
  %User{firstname: firstname, name: name}
end

@spec make([firstname: String.t, name: String.t]) :: User.t
def make(fields) do
  Kernel.struct!(User, fields)
end
```

### Creating modules and structs

If you need plenty of different data structures, you can use
```elixir
require QuickStruct
QuickStruct.define_module(User, [firstname: String.t, name: String.t])
QuickStruct.define_module(Pair, [:first, :second])
```
to create a module and the corresponding struct. So this is shorthand for:

```elixir
defmodule User do
  use QuickStruct, [firstname: String.t, name: String.t]
end
defmodule Pair do
  use QuickStruct, [:first, :second]
end
```

## License

Copyright © 2019 Active Group GmbH

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the LICENSE file for more details.
