defmodule QuickStruct do
  @moduledoc """
  Creates a struct with enforced keys, the type of the struct and
  a make function to create the struct.

  You have to "use" this module and give a list of fields or a
  keyword list with fields and specs to create a struct.

  As an alternative you can create a module and a struct together;
  just require QuickStruct and call `define_module/2`.

  ## Examples
  Assume you define the following structs:

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
  To create a struct you can either use `make/1` with a keyword list to specify
  the fields, or use `make`, where each argument is one field (order matters):

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
  defmacro make_struct(fields, args, opts \\ []) do
    quote do
      @enforce_keys unquote(fields)
      defstruct unquote(fields)

      @doc "Creates a #{__MODULE__}-struct from a keyword list."
      def make([{_, _} | _] = fields) do
        Kernel.struct!(__MODULE__, fields)
      end

      @doc "Creates a #{__MODULE__}-struct from the given ordered fields."
      def make(unquote_splicing(args)) do
        l =
          Enum.zip(unquote(fields), unquote(args))
          |> Enum.into([])

        Kernel.struct!(__MODULE__, l)
      end

      unquote do
        if Enum.empty?(args) do
          # we create another empty constructor to allow make([])
          quote do
            def make([]) do
              Kernel.struct!(__MODULE__, [])
            end
          end
        end
      end
      

      unquote do
        predicate = Keyword.get(opts, :predicate)
        if predicate do
          quote do
            @doc "Returns true if the passed value is a struct of type #{__MODULE__}, else false"
            @spec unquote(predicate)(any()) :: boolean()
            def unquote(predicate)(%__MODULE__{}), do: true
            def unquote(predicate)(_), do: false
          end
        end
      end

      @doc """
      Returns true if the given object is a #{__MODULE__}-struct, otherwise false.

      ## Examples

      Pair.is_struct(%User{firstname: "Jon", name: "Adams"}) # => false
      Pair.is_struct(%Pair{first: 1, second: 2}) # => true
      """
      @spec is_struct(any()) :: boolean()
      def is_struct(object), do: is_struct_of(object, __MODULE__)

      def is_struct_of(a,b), do: QuickStruct.is_struct_of(a,b)
    end
  end

  @doc !"""
  Checks if the field list actually is a keyword list, which means we have specs.
  """
  defp has_field_specs?([{_, _} | _]), do: true
  defp has_field_specs?(_), do: false


  @doc !"""
  This does something similar to Macro.generate_arguments/2, but
  with the original field names as arguments (better for generated
  documentation of the function).
  """
  defp prepare_args(fields), do: Enum.map(fields, &{&1, [], __MODULE__})

  defmacro __using__(opts) do
    maybe_specd_fields = Keyword.get(opts, :fields, [])

      if has_field_specs?(maybe_specd_fields) do
         fields = Keyword.keys(maybe_specd_fields)
         types = Keyword.values(maybe_specd_fields)
         args = prepare_args(fields)
        
         quote do
           @type t :: %__MODULE__{unquote_splicing(maybe_specd_fields)}
           @spec make(unquote(maybe_specd_fields)) :: __MODULE__.t()
           @spec make(unquote_splicing(types)) :: __MODULE__.t()

           QuickStruct.make_struct(unquote(fields), unquote(args), unquote(opts))
         end
      else
         fields = maybe_specd_fields
         args = prepare_args(fields)
     
         quote do
           QuickStruct.make_struct(unquote(fields), unquote(args), unquote(opts))
         end
    end
  end

  @doc """
  Defines a module together with a struct with the given field list.

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
  defmacro define_module(modulename, opts \\ []) do
    quote do
      defmodule unquote(modulename) do
        use QuickStruct, unquote(opts)
      end
    end
  end

  @doc """
  Generates a function which will generate a struct with some given default values.

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
