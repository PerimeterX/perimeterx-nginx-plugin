reCAPTCHA Example 
-----------------
> This folder contains an example of a reCAPTCHA implementation. The original PerimeterX reCAPTCHA page has been customized, with a different color background, some icons and some colored texts.

In order to use the example:

1. Create a block.html file in your application (or copy the one in this folder).   
 The `<body>` section **must** include (replacing <APP_ID> with your  PX App ID):

```html
<script>
    window._pxAppId = '<APP_ID>';
    window._pxJsClientSrc = 'https://client.perimeterx.net/<APP_ID>/main.min.js';
    window._pxHostUrl = 'https://collector-<APP_ID>.perimeterx.net';
</script>
<script src="https://captcha.px-cdn.perimeterx.net/recaptcha.js"></script>
```

2. Set the `_M.custom_block_url` to the location you have just defined (e.g. /block.html)
5. Set the `_M.redirect_on_custom_url` flag to **false**.
6. Change the `<APP_ID>` placeholder on the block.html page to the Application ID provided on the PerimeterX Portal.
