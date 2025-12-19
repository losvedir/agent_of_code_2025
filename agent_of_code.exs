Mix.install([:req, :jason])

defmodule AgentOfCode do
  require Logger

  @api_key "<redacted>"

  @model "gpt-5-mini-2025-08-07"
  # @model "gpt-5.2-2025-12-11"

  @system_prompt """
    You are Agent of Code, an agentic AI working on this year's (2025) Advent of Code problems. You are running in a
    directory with a subdirectory `aoc25` in which you can manipulate to store problem inputs, prompts, and typescript
    code to solve the problems. `aoc25` is a standard TypeScript app with a package.json file, etc.

    You have full access to an ordinary MacOS terminal, to `cat`, `grep`, etc, to learn the state of the `aoc25` project and update it.
    You invoke these unix commands via one of your tools, and it will prompt me to run the code and give you the results. Prefer read-only
    commands like `cat` to `sed` when not wanting to manipulate files, because those will be automatically accepted.
    You may also write typescript code, run tests, run your typescript code, etc.

    Each time you start up, introspect the state of the repo to see the next problem to work on, and keep working until
    that problem is solved. A "problem" in this case is "half" of a day, since each day has two parts. Your general approach
    should be to `cp -r` the template in `day00` if necessary, and get the prompt and input, then write tests, then
    write an implementation, and finally try to solve it, using a tool to submit it and learn the result. If you're starting
    up and part 1 had been solved previously, you'll only need to get the prompt again and update the tests and implementation.

    There are 12 problems this year.
  """

  def system_prompt, do: @system_prompt

  @tools [
    %{
      "type" => "function",
      "name" => "run_command",
      "description" => "Has the user execute the given shell command for you.",
      "parameters" => %{
        "type" => "object",
        "properties" => %{
          "cmd" => %{
            "type" => "string",
            "description" => "The verbatim command the user should execute"
          }
        },
        "required" => ["cmd"]
      }
    },
    %{
      "type" => "function",
      "name" => "get_prompt",
      "description" =>
        "Gets the Advent of Code prompt or partial prompt for a given day and writes it to the given path.",
      "parameters" => %{
        "type" => "object",
        "properties" => %{
          "day" => %{
            "type" => "string",
            "description" => "The Advent of Code day to get the prompt for."
          },
          "part" => %{
            "type" => "string",
            "description" => "Whether you're expecting just Part 1 or 2 (the full prompt)."
          },
          "path" => %{
            "type" => "string",
            "description" => "The path of the file to write the prompt at."
          }
        },
        "required" => ["day"]
      }
    },
    %{
      "type" => "function",
      "name" => "get_input",
      "description" =>
        "Gets the Advent of Code input for a given day and writes it to the given path.",
      "parameters" => %{
        "type" => "object",
        "properties" => %{
          "day" => %{
            "type" => "string",
            "description" => "The Advent of Code day to get the input for."
          },
          "path" => %{
            "type" => "string",
            "description" => "The path of the file to write the prompt at."
          }
        },
        "required" => ["day"]
      }
    },
    %{
      "type" => "function",
      "name" => "submit_result",
      "description" => "Submits the result for the given day.",
      "parameters" => %{
        "type" => "object",
        "properties" => %{
          "solution" => %{
            "type" => "string",
            "description" => "The solution to submit."
          },
          "day" => %{
            "type" => "string",
            "description" => "The day the solution is being submitted for."
          },
          "part" => %{
            "type" => "string",
            "description" => "Either 'one' or 'two' for the two parts of the day."
          }
        },
        "required" => ["solution", "day", "part"]
      }
    }
  ]

  def main do
    IO.puts("Welcome to Agent of Code. I'm your personal Agent to solve Advent of Code for you.")

    starting_input = [
      %{
        "content" => @system_prompt,
        "role" => "system",
        "type" => "message"
      }
    ]

    loop(starting_input)
  end

  def loop(input) do
    {:ok, %{body: %{"output" => output}}} = request(input)

    new_input =
      case List.last(output) do
        %{"type" => "function_call"} = function_call_request ->
          result = [
            %{
              "type" => "function_call_output",
              "call_id" => function_call_request["call_id"],
              "output" => Jason.encode!(handle_function_call(function_call_request))
            }
          ]

          input ++ output ++ result

        _ ->
          input ++ output
      end

    loop(new_input)
  end

  def request(input) do
    Req.post("https://api.openai.com/v1/responses",
      headers: [authorization: "Bearer #{@api_key}"],
      json: %{
        model: @model,
        input: input,
        tools: @tools
      }
    )
  end

  def handle_function_call(%{"name" => "run_command", "arguments" => args}) do
    cmd = Jason.decode!(args)["cmd"]

    case cmd do
      "ls " <> _ ->
        IO.puts("Autorunning safe command: `#{cmd}`")

      "cat " <> _ ->
        IO.puts("Autorunning safe command: `#{cmd}`")

      "head " <> _ ->
        IO.puts("Autorunning safe command: `#{cmd}`")

      "tail " <> _ ->
        IO.puts("Autorunning safe command: `#{cmd}`")

      _ ->
        IO.gets("Okay to run? --- `#{cmd}` (Enter to Accept; Ctrl-C to abort)")
    end

    {output, _exit_status} = System.shell(cmd)
    IO.puts("------------")
    IO.puts(output)
    IO.puts("------------\n\n")
    output
  end

  def handle_function_call(%{"name" => "get_prompt", "arguments" => args}) do
    day = Jason.decode!(args)["day"]
    part = Jason.decode!(args)["part"]
    path = Jason.decode!(args)["path"]

    IO.gets("Get Prompt for Day #{day}, part #{part} and write it to #{path}\n")
  end

  def handle_function_call(%{"name" => "get_input", "arguments" => args}) do
    day = Jason.decode!(args)["day"]
    path = Jason.decode!(args)["path"]

    IO.gets("Get Input for Day #{day} and write it to #{path}\n")
  end

  def handle_function_call(%{"name" => "submit_result", "arguments" => args}) do
    solution = Jason.decode!(args)["solution"]
    day = Jason.decode!(args)["day"]
    part = Jason.decode!(args)["part"]

    IO.gets("Submit #{solution} for Day #{day} part #{part}: #{solution}\n")
  end
end

Application.ensure_all_started(:logger)

Logger.configure(level: :debug)

AgentOfCode.main()
