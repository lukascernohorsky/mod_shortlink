-module(m_shortlink).
-author("OpenAI Assistant").

-include_lib("zotonic.hrl").
-include("mod_shortlink.hrl").

-export([
    get/2,
    insert/4,
    incr_clicks/2,
    stats/3
]).

-ifdef(TEST).
-export([validate_url/1, random_keyword/1]).
-endif.

-define(DEFAULT_KEYWORD_LENGTH, 6).
-define(KEYWORD_CHARS, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").

%% @doc Fetch a shortlink by its keyword.
-spec get(z:string(), z:context()) -> {ok, map()} | not_found | {error, term()}.
get(Keyword, Context) when is_binary(Keyword); is_list(Keyword) ->
    case z_db:q(
             \"select id, keyword, url, title, timestamp, clicks, ip from shortlink where keyword = $1\",
             [Keyword],
             Context) of
        [] ->
            not_found;
        [{Id, Kw, Url, Title, Ts, Clicks, Ip}] ->
            {ok, #{id => Id, keyword => Kw, url => Url, title => Title, timestamp => Ts, clicks => Clicks, ip => Ip}}
    end.

%% @doc Insert a new shortlink; when Keyword is empty, generate one.
-spec insert(z:string(), z:string() | undefined, z:string() | undefined, z:context()) ->
    {ok, map()} | {error, term()}.
insert(Url, Keyword0, Title, Context) ->
    case validate_url(Url) of
        true ->
            Keyword = ensure_keyword(Keyword0, Context),
            try_create_link(Url, Keyword, Title, Context);
        {error, _} = Error ->
            Error
    end.

%% @doc Increment click counter for the given keyword.
-spec incr_clicks(z:string(), z:context()) -> ok | {error, term()}.
incr_clicks(Keyword, Context) ->
    z_db:q(
        \"update shortlink set clicks = clicks + 1 where keyword = $1\",
        [Keyword],
        Context),
    ok.

%% @doc Return stats based on a filter.
-spec stats(atom() | binary(), integer(), z:context()) -> {ok, [map()]}.
stats(Filter, Limit, Context) when is_integer(Limit), Limit > 0 ->
    Sql = stats_sql(Filter),
    Rows = z_db:q(Sql, [Limit], Context),
    {ok, [row_to_map(Row) || Row <- Rows]}.

%% Internal helpers

row_to_map({Id, Keyword, Url, Title, Ts, Clicks, Ip}) ->
    #{id => Id, keyword => Keyword, url => Url, title => Title, timestamp => Ts, clicks => Clicks, ip => Ip}.

stats_sql(Filter) when Filter == top; Filter == <<"top">> ->
    \"select id, keyword, url, title, timestamp, clicks, ip from shortlink order by clicks desc limit $1\";
stats_sql(Filter) when Filter == bottom; Filter == <<"bottom">> ->
    \"select id, keyword, url, title, timestamp, clicks, ip from shortlink order by clicks asc limit $1\";
stats_sql(Filter) when Filter == rand; Filter == <<"rand">> ->
    \"select id, keyword, url, title, timestamp, clicks, ip from shortlink order by random() limit $1\";
stats_sql(_Filter) ->
    \"select id, keyword, url, title, timestamp, clicks, ip from shortlink order by timestamp desc limit $1\".

ensure_keyword(undefined, _Context) ->
    random_keyword(?DEFAULT_KEYWORD_LENGTH);
ensure_keyword(<<>>, _Context) ->
    random_keyword(?DEFAULT_KEYWORD_LENGTH);
ensure_keyword("", _Context) ->
    random_keyword(?DEFAULT_KEYWORD_LENGTH);
ensure_keyword(Keyword, _Context) ->
    Keyword.

random_keyword(Len) when Len > 0 ->
    seed_rand(),
    random_keyword(Len, []).

random_keyword(0, Acc) ->
    list_to_binary(lists:reverse(Acc));
random_keyword(N, Acc) ->
    CharList = ?KEYWORD_CHARS,
    Index = rand:uniform(length(CharList)),
    random_keyword(N - 1, [lists:nth(Index, CharList) | Acc]).

seed_rand() ->
    _ = rand:seed(exsplus, {erlang:monotonic_time(), erlang:unique_integer(), erlang:phash2(self())}),
    ok.

try_create_link(Url, Keyword, Title, Context) ->
    Sql =
        \"insert into shortlink (url, keyword, title) values ($1, $2, $3) returning id, keyword, url, title, timestamp, clicks, ip\",
    try
        case z_db:q(Sql, [Url, Keyword, Title], Context) of
            [{Id, Kw, LUrl, LTitle, Ts, Clicks, Ip}] ->
                Notification = #shortlink_created{id = Id, url = LUrl, keyword = Kw},
                z_notifier:notify(Notification, Context),
                {ok, row_to_map({Id, Kw, LUrl, LTitle, Ts, Clicks, Ip})}
        end
    catch
        throw:{error, duplicate} ->
            {error, duplicate_keyword};
        error:{badmatch, _} ->
            {error, insertion_failed};
        error:{badarg, Reason} ->
            {error, Reason}
    end.

validate_url(Url) when is_binary(Url) ->
    validate_url(binary_to_list(Url));
validate_url(Url) when is_list(Url) ->
    case uri_string:parse(Url) of
        #{scheme := Scheme, host := _Host} when Scheme =/= undefined, Scheme =/= <<>> ->
            true;
        _ ->
            {error, invalid_url}
    end.
