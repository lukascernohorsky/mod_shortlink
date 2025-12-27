-module(mod_shortlink).
-author("OpenAI Assistant").
-behaviour(zotonic_module).

-include_lib("zotonic.hrl").

%% API
-export([
    init/1,
    finish/1,
    manage_schema/2,
    install/1,
    add_link/3,
    delete_link/2
]).

%% @doc Initialize the module.
-spec init(z:context()) -> ok.
init(_Context) ->
    ok.

%% @doc Cleanup callback when the module stops.
-spec finish(z:context()) -> ok.
finish(_Context) ->
    ok.

%% @doc Install callback for backward compatibility with scripts.
-spec install(z:context()) -> ok.
install(Context) ->
    manage_schema(install, Context).

%% @doc Ensure the database schema exists.
-spec manage_schema(install | {upgrade, term()}, z:context()) -> ok | {error, term()}.
manage_schema(install, Context) ->
    z_db:transaction(
        fun(Ctx) ->
            z_db:q(
                \"\"\"
                create table if not exists shortlink (
                    id serial primary key,
                    keyword varchar(100) unique not null,
                    url text not null,
                    title varchar(255),
                    timestamp timestamptz not null default now(),
                    clicks integer not null default 0,
                    ip inet
                )
                \"\"\",
                Ctx),
            ok
        end,
        Context
    );
manage_schema({upgrade, _Version}, _Context) ->
    %% Add migrations here for future versions.
    ok.

%% @doc Manually add a new short link.
-spec add_link(z:context(), z:string(), z:string()) -> {ok, map()} | {error, term()}.
add_link(Context, Url, Keyword) ->
    m_shortlink:insert(Url, Keyword, undefined, Context).

%% @doc Delete a short link by keyword.
-spec delete_link(z:context(), z:string()) -> ok | {error, term()}.
delete_link(Context, Keyword) ->
    z_db:q(
        \"delete from shortlink where keyword = $1\",
        [Keyword],
        Context),
    ok.
