funCAPTCHA Example 
-----------------
> This folder contains an example of a funCAPTCHA implementation. The original PerimeterX funCAPTCHA page has been customized, with a different color background, some icons and some colored texts.

In order to use the example:

1. Create a block.html file in your application (or copy the one in this folder), and define a route for it in your nginx.conf file.
2. Set the `_M.custom_block_url` to the location you have just defined (e.g. /block.html)
4. Set the `_M.captcha_provider` parameter to `funCaptcha`
5. Set the `_M.redirect_on_custom_url` flag to **true**
6. Change the `<APP_ID>` placeholder on the block.html page to the Application ID provided on the PerimeterX Portal.


You are now Blocking requests providing a CAPTCHA to the user for cleanup.

>Note: Please notice when using redirects, several elements must be included in your HTML file.

* The `<body>` section **must** include (replace <APP_ID> with provided PX app ID):

```html
<script>
    window._pxAppId = '<APP_ID>';
    window._pxJsClientSrc = 'https://client.perimeterx.net/<APP_ID>/main.min.js';
    window._pxHostUrl = 'https://collector-<APP_ID>.perimeterx.net';
</script>
<script src="https://captcha.px-cdn.perimeterx.net/funcaptcha.js"></script>
```
* In its HTML structure, where you want to place the captcha element, the `<body>` section **must** include:

```
<div id="px-captcha"></div>
```

