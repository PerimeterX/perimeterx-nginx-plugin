Block Page Example 
-----------------
> This folder contains an example of a Block Page implementation. The original PerimeterX block page has been customized, with a different color background, some icons and some colored texts.

In order to use the example:

1. Create a block.html file in your application (or copy the one in this folder).   
 The `<body>` section **must** include (replacing <APP_ID> with your  PX App ID):

 ```html
<script>
    window._pxAppId = '<APP_ID>';
    window._pxJsClientSrc = 'https://client.perimeterx.net/<APP_ID>/main.min.js';
    window._pxHostUrl = 'https://collector-<APP_ID>.perimeterx.net';
 </script>
 <script src="https://captcha.px-cdn.perimeterx.net/<APP_ID>/captcha.js?a=b&m=0"></script>
```

2. Set the `_M.custom_block_url` to the location you have just defined (e.g. /block.html)
3. Change the `<APP_ID>` placeholder on the block.html page to the Application ID provided on the PerimeterX Portal.

### Redirecting to a Custom Block Page
Instead of rendering the block page under the current URL, you can have the Enforcer redirect the blocked request to a different URL by setting `_M.redirect_on_custom_url` to **true**.

### Adding Reference ID
To display the block reference ID on the block page, you must fetch the `uuid` parameter either from the window object (no redirect) or from the page’s query parameters (block page with redirect). Once you have the `uuid` value, you can modify the page’s HTML dynamically.

Example:

```html
<p>
    Reference ID: <span id="refid"></span>
</p>
```
```html
<script>
    (function setRefId() {
        var pxUuid = window._pxUuid;
        if (!pxUuid) {
            url = window.location.href;
            var regex = new RegExp('[?&]uuid(=([^&#]*)|&|#|$)');
            var results = regex.exec(url);
            pxUuid = results && results.length > 2 ? results[2] : '';
            pxUuid = decodeURIComponent(pxUuid.replace(/\+/g, ' '));
        }
        document.getElementById("refid").innerHTML = pxUuid;
    })();
</script>
```
