{% extends "admin/_admin_menu_module.tpl" %}

{% block module_menu %}
<li>
    <a href="{% url admin_shortlink %}">{_ Shortlinks _}</a>
</li>
{% endblock %}
