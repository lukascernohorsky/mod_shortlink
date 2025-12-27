-module(dispatch_mod_shortlink).
-author("OpenAI Assistant").

-export([rules/0]).

%% @doc Dispatch rules for the shortlink module.
rules() ->
    [
        {shortlink_api, [
            {prefix, [<<"api">>, <<"shortlink">>]},
            {controller, controller_shortlink_api}
        ]},
        {shortlink_redirect, [
            {path, [keyword]},
            {constraints, [{keyword, "[A-Za-z0-9_-]+"}]},
            {controller, controller_shortlink_redirect}
        ]}
    ].
