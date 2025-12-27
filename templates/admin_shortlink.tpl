{% extends "admin_base.tpl" %}
{% block title %}{_ Shortlinks _}{% endblock %}

{% block content %}
<div class="row">
    <div class="col-md-6">
        <h2>{_ Create shortlink _}</h2>
        <form method="post" action="/api/shortlink/shorturl" class="form-horizontal">
            <div class="form-group">
                <label class="control-label" for="url">{_ URL _}</label>
                <input type="url" class="form-control" id="url" name="url" required>
            </div>
            <div class="form-group">
                <label class="control-label" for="keyword">{_ Keyword (optional) _}</label>
                <input type="text" class="form-control" id="keyword" name="keyword" maxlength="100">
            </div>
            <div class="form-group">
                <label class="control-label" for="title">{_ Title _}</label>
                <input type="text" class="form-control" id="title" name="title">
            </div>
            <button type="submit" class="btn btn-primary">{_ Shorten _}</button>
        </form>
    </div>
    <div class="col-md-6">
        <h2>{_ Recent links _}</h2>
        <div class="table-responsive">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>{_ Keyword _}</th>
                        <th>{_ URL _}</th>
                        <th>{_ Clicks _}</th>
                    </tr>
                </thead>
                <tbody>
                    {% for link in m.shortlink.stats.last[limit=10] %}
                    <tr>
                        <td>{{ link.keyword }}</td>
                        <td><a href="/{{ link.keyword }}">{{ link.url }}</a></td>
                        <td>{{ link.clicks }}</td>
                    </tr>
                    {% empty %}
                    <tr>
                        <td colspan="3">{_ No links yet. _}</td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</div>
{% endblock %}
