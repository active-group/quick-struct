defmodule QuickStruct do
  @moduledoc """
  Creates a struct with enforced keys, the type of the struct and
  a make function to create the struct.

  You have to "use" this module and give a list of fields or a
  keyword list with fields and specs to create a struct.

  As an alternative you can create a module and a struct together,
  therefor require QuickStruct and call `define_module/2`.

  ## Examples
  Imagine you define the following structs:

  ```
  defmodule QuickStructTest.User do
    use QuickStruct, [firstname: String.t, name: String.t]
  end
  defmodule QuickStructTest.Pair do
    use QuickStruct, [:first, :second]
  end
  ```

  Or equivalent:

  ```
  require QuickStruct
  QuickStruct.define_module QuickStructTest.User, [firstname: String.t, name: String.t]
  QuickStruct.define_module QuickStructTest.Pair, [:first, :second]
  ```
  To create a struct you can either use `make/1` with a keyword-list to specify
  the fields or use `make`, where each argument is one field (order matters):

      iex> alias QuickStructTest.User
      iex> User.make("Jon", "Adams")
      %User{firstname: "Jon", name: "Adams"}
      iex> User.make([name: "Adams", firstname: "Jon"])
      %User{firstname: "Jon", name: "Adams"}

      iex> alias QuickStructTest.Pair
      iex> Pair.make(1, 0)
      %Pair{a: 1, b: 0}
      iex> Pair.make([a: "My", b: "String"])
      %Pair{a: "My", b: "String"}

  """

  @doc """
  Returns true if the given object is a struct of the given module, otherwise false.

  ## Examples

      iex> alias QuickStructTest.User
      iex> QuickStruct.is_struct_of(%User{firstname: "Jon", name: "Adams"}, QuickStructTest.User)
      true
      iex> QuickStruct.is_struct_of(%User{firstname: "Jon", name: "Adams"}, MyModule)
      false

  """
  @spec is_struct_of(any(), module()) :: boolean()
  def is_struct_of(%{__struct__: struct_module}, module), do: struct_module == module
  def is_struct_of(_, _), do: false

  @doc false
  defmacro struct(fields, args) do
    quote do
      @enforce_keys unquote(fields)
      defstruct unquote(fields)

      @doc "Creates a #{__MODULE__}-struct from a keyword list."
      def make([_ | _] = fields) do
        Kernel.struct!(__MODULE__, fields)
      end

      @doc "Creates a #{__MODULE__}-struct from the given ordered fields."
      def make(unquote_splicing(args)) do
        l =
          Enum.zip(unquote(fields), unquote(args))
          |> Enum.into([])

        Kernel.struct!(__MODULE__, l)
      end

      @doc """
      Returns true if the given object is a #{__MODULE__}-struct, otherwise false.

      ## Examples

      Pair.is_struct(%User{firstname: "Jon", name: "Adams"}) # => false
      Pair.is_struct(%Pair{first: 1, second: 2}) # => true
      """
      @spec is_struct(any()) :: boolean()
      def is_struct(object), do: QuickStruct.is_struct_of(object, __MODULE__)
    end
  end

  defmacro __using__([{_, _} | _] = fieldspecs) do
    fields = Keyword.keys(fieldspecs)
    types = Keyword.values(fieldspecs)
    args = Enum.map(fields, &{&1, [], __MODULE__})
    # This does something similar to Macro.generate_arguments/2, but
    # with the original fieldnames as arguments (better for generated
    # documentation of the function)

    quote do
      @type t :: %__MODULE__{unquote_splicing(fieldspecs)}
      @spec make(unquote(fieldspecs)) :: __MODULE__.t()
      @spec make(unquote_splicing(types)) :: __MODULE__.t()
      QuickStruct.struct(unquote(fields), unquote(args))
    end
  end

  defmacro __using__([]) do
    quote do
      defstruct []

      @type t :: %__MODULE__{}

      @doc "Creates a #{__MODULE__}-struct."
      @spec make([]) :: __MODULE__.t()
      def make([] \\ []) do
        Kernel.struct!(__MODULE__, [])
      end

      @doc """
      Returns true if the given object is a #{__MODULE__}-struct, otherwise false.

      ## Example

      """
      @spec is_struct(any()) :: boolean()
      def is_struct(object), do: QuickStruct.is_struct_of(object, __MODULE__)
    end
  end

  defmacro __using__(fields) when is_list(fields) do
    args = Enum.map(fields, &{&1, [], __MODULE__})

    quote do
      QuickStruct.struct(unquote(fields), unquote(args))
    end
  end

  @doc """
  Defines a module and a struct with the given field-list.

  ## Example

  ```
  require QuickStruct
  QuickStruct.define_module(MyDate, [day: integer(), month: integer(), year: integer()])
  new_year = %MyDate{day: 1, month: 1, year: 2000}
  ```

  This is equivalent to:
  ```
  defmodule MyDate do
    use QuickStruct, [day: integer(), month: integer(), year: integer()]
  end
  new_year = %MyDate{day: 1, month: 1, year: 2000}
  ```
  """
  @spec define_module(module(), keyword()) :: {:defmodule, keyword(), keyword()}
  defmacro define_module(modulename, fields) do
    quote do
      defmodule unquote(modulename) do
        use QuickStruct, unquote(fields)
      end
    end
  end

  @doc """
  Generates a function, which will generate a struct with some given default values.

  ## Example
  ```
  defmodule Triple do
    use QuickStruct, [:first, :second, :third]
    QuickStruct.constructor_with_defaults([third: 0])
  end
  pair = Triple.make_with_defaults([first: 24, second: 12])
  # => %Triple{first: 24, second: 12, third: 0}
  ```
  """
  @spec constructor_with_defaults(keyword()) :: {:__block__, [], [any()]}
  defmacro constructor_with_defaults(defaults) do
    quote do
      @doc "Creates a #{__MODULE__}-struct from a keyword list with defaults: #{
             unquote(inspect(defaults))
           }."
      @spec make_with_defaults(keyword()) :: __MODULE__.t()
      def make_with_defaults(fields) do
        make(Keyword.merge(unquote(defaults), fields))
      end
    end
  end
end
