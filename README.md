This is a project which developed by Xerions (https://github.com/xerions). But this project as two issues. I sloved one of the issue. This is the solved version.

There are some unresolved questions:

Diameter sources have the inherits and it requires the correct file order. If b inherits a then a should be compiled before b. In rebar_dia_compiler it is solved by dia_first_files but it is not possible to add that kind of option to this compile so I may suggest to use alphabetic order to naming dia sources for now.

Diameter compiler generates erl and hrl file. It is possible in Elixir to work with records from hrl file but I don't know a good way to work with defined constants.