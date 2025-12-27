{% extends "admin_base.tpl" %}
{% block title %}{_ Shortlink statistics _}{% endblock %}

{% block content %}
<h2>{_ Shortlink statistics _}</h2>
<p>{_ Placeholder for chart rendering. Integrate Chart.js or Google Charts. _}</p>
<div id="shortlink-stats-chart" style="min-height:240px;"></div>
<div class="table-responsive">
    <table class="table table-striped">
        <thead>
            <tr>
                <th>{_ Keyword _}</th>
                <th>{_ URL _}</th>
                <th>{_ Clicks _}</th>
                <th>{_ Created _}</th>
            </tr>
        </thead>
        <tbody>
            {% for link in m.shortlink.stats.top[limit=20] %}
            <tr>
                <td>{{ link.keyword }}</td>
                <td><a href="/{{ link.keyword }}">{{ link.url }}</a></td>
                <td>{{ link.clicks }}</td>
                <td>{{ link.timestamp }}</td>
            </tr>
            {% empty %}
            <tr>
                <td colspan="4">{_ No statistics to display. _}</td>
            </tr>
            {% endfor %}
        </tbody>
    </table>
</div>
{% endblock %}
