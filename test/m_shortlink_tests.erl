-module(m_shortlink_tests).

-include_lib("eunit/include/eunit.hrl").

keyword_length_test() ->
    Keyword = m_shortlink:random_keyword(8),
    ?assertEqual(8, byte_size(Keyword)).

keyword_charset_test() ->
    Keyword = m_shortlink:random_keyword(12),
    Allowed = sets:from_list("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"),
    ?assert(
        lists:all(
            fun(C) -> sets:is_element(C, Allowed) end,
            binary:bin_to_list(Keyword)
        )
    ).

valid_url_test() ->
    ?assertEqual(true, m_shortlink:validate_url("https://example.com/path")).

invalid_url_test() ->
    ?assertMatch({error, invalid_url}, m_shortlink:validate_url("ftp:///")).
