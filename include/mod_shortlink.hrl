-record(shortlink_created, {
    id       :: integer(),
    url      :: binary() | list(),
    keyword  :: binary() | list()
}).

-record(shortlink_redirect, {
    id           :: integer(),
    url          :: binary() | list(),
    keyword      :: binary() | list(),
    request_data :: term()
}).
