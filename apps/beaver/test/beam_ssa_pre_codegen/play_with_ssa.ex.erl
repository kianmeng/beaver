{b_module,#{},'Elixir.PlayWithSsa',
    [{'__info__',1},{hello,0},{module_info,0},{module_info,1}],
    [],
    [{b_function,
         #{func_info => {'Elixir.PlayWithSsa','__info__',1},
           live_intervals =>
               [{{b_var,0},[{0,1},{0,2},{10,11},{14,15}]},
                {{b_var,4},[{15,17}]},
                {{b_var,{'@ssa_ret',9}},[{11,13}]}],
           parameter_info => #{},
           registers =>
               #{{b_var,0} => {x,0},
                 {b_var,4} => {x,0},
                 {b_var,{'@ssa_ret',9}} => {x,0}}},
         [{b_var,0}],
         #{0 =>
               {b_blk,#{},[],
                   {b_switch,
                       #{n => 1},
                       {b_var,0},
                       3,
                       [{{b_literal,attributes},18},
                        {{b_literal,compile},18},
                        {{b_literal,deprecated},13},
                        {{b_literal,exports_md5},15},
                        {{b_literal,functions},14},
                        {{b_literal,macros},13},
                        {{b_literal,md5},18},
                        {{b_literal,module},12}]}},
           3 =>
               {b_blk,#{},
                   [{b_set,
                        #{inlined => {'-inlined-__info__/1-',1},n => 15},
                        {b_var,4},
                        call,
                        [{b_local,{b_literal,'-inlined-__info__/1-'},1},
                         {b_var,0}]}],
                   {b_ret,#{n => 17},{b_var,4}}},
           12 =>
               {b_blk,#{},[],
                   {b_ret,#{n => 3},{b_literal,'Elixir.PlayWithSsa'}}},
           13 => {b_blk,#{},[],{b_ret,#{n => 9},{b_literal,[]}}},
           14 => {b_blk,#{},[],{b_ret,#{n => 5},{b_literal,[{hello,0}]}}},
           15 =>
               {b_blk,#{},[],
                   {b_ret,
                       #{n => 7},
                       {b_literal,
                           <<240,105,247,119,22,50,219,207,90,95,127,92,159,
                             46,131,169>>}}},
           18 =>
               {b_blk,#{},
                   [{b_set,
                        #{n => 11},
                        {b_var,{'@ssa_ret',9}},
                        call,
                        [{b_remote,
                             {b_literal,erlang},
                             {b_literal,get_module_info},
                             2},
                         {b_literal,'Elixir.PlayWithSsa'},
                         {b_var,0}]}],
                   {b_ret,#{n => 13},{b_var,{'@ssa_ret',9}}}}},
         21},
     {b_function,
         #{func_info => {'Elixir.PlayWithSsa',hello,0},
           live_intervals => [],
           location => {"lib/play_with_ssa.ex",15},
           parameter_info => #{},registers => #{}},
         [],
         #{0 => {b_blk,#{},[],{b_ret,#{n => 1},{b_literal,world}}}},
         3},
     {b_function,
         #{func_info => {'Elixir.PlayWithSsa',module_info,0},
           live_intervals => [{{b_var,{'@ssa_ret',3}},[{1,3}]}],
           parameter_info => #{},
           registers => #{{b_var,{'@ssa_ret',3}} => {x,0}}},
         [],
         #{0 =>
               {b_blk,#{},
                   [{b_set,
                        #{n => 1},
                        {b_var,{'@ssa_ret',3}},
                        call,
                        [{b_remote,
                             {b_literal,erlang},
                             {b_literal,get_module_info},
                             1},
                         {b_literal,'Elixir.PlayWithSsa'}]}],
                   {b_ret,#{n => 3},{b_var,{'@ssa_ret',3}}}}},
         5},
     {b_function,
         #{func_info => {'Elixir.PlayWithSsa',module_info,1},
           live_intervals =>
               [{{b_var,0},[{0,1}]},{{b_var,{'@ssa_ret',3}},[{1,3}]}],
           parameter_info => #{},
           registers => #{{b_var,0} => {x,0},{b_var,{'@ssa_ret',3}} => {x,0}}},
         [{b_var,0}],
         #{0 =>
               {b_blk,#{},
                   [{b_set,
                        #{n => 1},
                        {b_var,{'@ssa_ret',3}},
                        call,
                        [{b_remote,
                             {b_literal,erlang},
                             {b_literal,get_module_info},
                             2},
                         {b_literal,'Elixir.PlayWithSsa'},
                         {b_var,0}]}],
                   {b_ret,#{n => 3},{b_var,{'@ssa_ret',3}}}}},
         5},
     {b_function,
         #{func_info => {'Elixir.PlayWithSsa','-inlined-__info__/1-',1},
           location => [],parameter_info => #{},
           registers => #{{b_var,0} => {x,0},{b_var,'@ssa_ret'} => {x,0}}},
         [{b_var,0}],
         #{0 =>
               {b_blk,#{},
                   [{b_set,#{},
                        {b_var,'@ssa_ret'},
                        match_fail,
                        [{b_literal,function_clause},{b_var,0}]}],
                   {b_ret,#{},{b_var,'@ssa_ret'}}}},
         1}]}.