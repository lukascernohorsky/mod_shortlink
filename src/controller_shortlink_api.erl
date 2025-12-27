-module(controller_shortlink_api).
-author("OpenAI Assistant").

-include_lib("zotonic.hrl").

-export([process/2]).

-define(DEFAULT_LIMIT, 10).

%% @doc Entry point for the shortlink HTTP API.
-spec process(wrq:reqdata(), z:context()) -> {binary(), z:context()}.
process(ReqData, Context) ->
    Action = z_context:get_q(<<"action">>, Context),
    Format = preferred_format(ReqData),
    case dispatch(Action, Format, Context) of
        {ok, Body, Ctx1} ->
            {{halt, 200}, wrq:set_resp_body(Body, ReqData), Ctx1};
        {error, Status, Body, Ctx1} ->
            {{halt, Status}, wrq:set_resp_body(Body, ReqData), Ctx1}
    end.

dispatch(<<"shorturl">>, Format, Context) ->
    Url = z_context:get_q(<<"url">>, Context),
    Keyword = z_context:get_q(<<"keyword">>, Context),
    Title = z_context:get_q(<<"title">>, Context),
    respond(shorturl(Url, Keyword, Title, Context), Format, Context);
dispatch(<<"expand">>, Format, Context) ->
    ShortUrl = z_context:get_q(<<"shorturl">>, Context),
    respond(expand(ShortUrl, Context), Format, Context);
dispatch(<<"url-stats">>, Format, Context) ->
    ShortUrl = z_context:get_q(<<"shorturl">>, Context),
    respond(url_stats(ShortUrl, Context), Format, Context);
dispatch(<<"stats">>, Format, Context) ->
    Filter = z_context:get_q(<<"filter">>, Context),
    Limit = z_convert:to_integer(z_context:get_q(<<"limit">>, Context, ?DEFAULT_LIMIT)),
    respond(stats(Filter, Limit, Context), Format, Context);
dispatch(<<"db-stats">>, Format, Context) ->
    respond(db_stats(Context), Format, Context);
dispatch(<<"version">>, Format, Context) ->
    respond({ok, #{version => <<"1.2">>}}, Format, Context);
dispatch(_Unknown, Format, Context) ->
    respond({error, {bad_request, <<"unknown_action">>}}, Format, Context).

shorturl(undefined, _Keyword, _Title, _Context) ->
    {error, {bad_request, <<"missing_url">>}};
shorturl(Url, Keyword, Title, Context) ->
    case m_shortlink:insert(Url, Keyword, Title, Context) of
        {ok, Data} ->
            Host = z_context:abs_url(<<"/", (maps:get(keyword, Data)) /binary>>, Context),
            {ok, Data#{shorturl => Host, status => <<"success">>}};
        {error, Reason} ->
            {error, {bad_request, Reason}}
    end.

expand(undefined, _Context) ->
    {error, {bad_request, <<"missing_shorturl">>}};
expand(ShortUrl, Context) ->
    Keyword = last_segment(ShortUrl),
    case m_shortlink:get(Keyword, Context) of
        {ok, Map} ->
            {ok, #{longurl => maps:get(url, Map)}};
        not_found ->
            {error, {not_found, <<"unknown_shorturl">>}}
    end.

url_stats(undefined, _Context) ->
    {error, {bad_request, <<"missing_shorturl">>}};
url_stats(ShortUrl, Context) ->
    Keyword = last_segment(ShortUrl),
    case m_shortlink:get(Keyword, Context) of
        {ok, Map} ->
            {ok, Map};
        not_found ->
            {error, {not_found, <<"unknown_shorturl">>}}
    end.

stats(Filter, Limit, Context) ->
    case m_shortlink:stats(Filter, Limit, Context) of
        {ok, List} ->
            {ok, #{results => List, filter => Filter}};
        {error, Reason} ->
            {error, {bad_request, Reason}}
    end.

db_stats(Context) ->
    TotalLinks = z_db:q1(\"select count(*) from shortlink\", Context),
    TotalClicks = z_db:q1(\"select coalesce(sum(clicks), 0) from shortlink\", Context),
    {ok, #{links => TotalLinks, clicks => TotalClicks}}.

preferred_format(ReqData) ->
    case wrq:get_resp_content_type(ReqData) of
        undefined -> <<"json">>;
        {_, _} -> <<"json">>;
        <<"application/xml">> -> <<"xml">>;
        <<"text/plain">> -> <<"simple">>;
        _ -> <<"json">>
    end.

respond({ok, Data}, <<"xml">>, Context) ->
    Body = z_xml:encode_map(Data),
    {ok, Body, z_context:set_resp_content_type(<<"application/xml">>, Context)};
respond({ok, Data}, <<"simple">>, Context) ->
    Body = iolist_to_binary([io_lib:format(\"~p\", [Data])]),
    {ok, Body, z_context:set_resp_content_type(<<"text/plain">>, Context)};
respond({ok, Data}, _Format, Context) ->
    Body = z_json:encode(Data),
    {ok, Body, z_context:set_resp_content_type(<<"application/json">>, Context)};
respond({error, {StatusAtom, Reason}}, Format, Context) ->
    Status = status_code(StatusAtom),
    {ok, Body, Ctx1} = respond({ok, #{error => Reason}}, Format, Context),
    {error, Status, Body, Ctx1}.

status_code(bad_request) -> 400;
status_code(unauthorized) -> 401;
status_code(not_found) -> 404;
status_code(_) -> 400.

last_segment(Url) when is_binary(Url) ->
    last_segment(binary_to_list(Url));
last_segment(Url) when is_list(Url) ->
    Segments = string:tokens(Url, \"/\"),
    list_to_binary(lists:last(Segments)).
