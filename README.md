# HTML to Luanto Hypertext

An API to convert HTML into Luanti Hypertext.

## `html_to_luanti.parse(html, config)`

Parse HTML string and return hypertext.

* `html`: HTML in string
* `config.url_base`: Prefix of links when the FQDN is not found, i.e. it starts with a slash. E.g. `https://www.example.com`.
* `config.anchor_base`: Prefix of links when the link is an anchor, i.e. it starts with a hash. E.g. `https://www.example.com/page`.

## `html_to_luanti.helpers.parse_website(http, url, callback)`

Parse a web page.

* `http`: Luanti HTTP API. The mod calling it should be put into `security.http_mods` and be responsible to retrieve the HTTP API.
* `url`: The website's URL.
* `callback(hypertext)`: Called after the web page is retrieved and the HTML is parsed. `hypertext` may be `nil` on failure.

## `html_to_luanti.helpers.parse_mediawiki_page(http, api, page, callback)`

Parse a MediaWiki page.

* `http`: Luanti HTTP API. The mod calling it should be put into `security.http_mods` and be responsible to retrieve the HTTP API.
* `api`: String, URL to the `api.php` of the MediaWiki installation.
* `page`: String, title of the page to be parsed.
* `callback(hypertext, revid)`: Called after the page is retrieved and the HTML is parsed. `hypertext` and `revid` may be `nil` on failure.
