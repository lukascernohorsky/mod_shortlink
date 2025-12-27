-module(controller_shortlink_redirect).
-author("OpenAI Assistant").

-include_lib("zotonic.hrl").
-include("mod_shortlink.hrl").

-export([process/2]).

%% @doc Redirect controller for shortlinks.
-spec process(wrq:reqdata(), z:context()) -> {{halt, integer()}, wrq:reqdata(), z:context()}.
process(ReqData, Context) ->
    Keyword = z_context:get_q(<<"keyword">>, Context),
    case m_shortlink:get(Keyword, Context) of
        {ok, #{url := Url} = Link} ->
            notify_redirect(Link, ReqData, Context),
            spawn(fun() -> m_shortlink:incr_clicks(Keyword, Context) end),
            {Code, RCtx} = redirect_code(Context),
            {{halt, Code}, wrq:do_redirect(Url, ReqData), RCtx};
        _ ->
            {{halt, 404}, wrq:set_resp_body(<<"Not found">>, ReqData), Context}
    end.

notify_redirect(#{id := Id, url := Url, keyword := Keyword}, ReqData, Context) ->
    Notification = #shortlink_redirect{
        id = Id,
        url = Url,
        keyword = Keyword,
        request_data = ReqData
    },
    z_notifier:notify(Notification, Context).

redirect_code(Context) ->
    case m_config:get_value(mod_shortlink, redirect_code, Context) of
        <<"302">> -> {302, Context};
        <<"301">> -> {301, Context};
        302 -> {302, Context};
        _ -> {301, Context}
    end.
