reCAPTCHA Example 
-----------------
> This folder contains an example of a reCAPTCHA implementation. The original PerimeterX reCAPTCHA page has been customized, with a different color background, some icons and some colored texts.

In order to use the example:

1. Create a block.html file in your application (or copy the one in this folder).   
 The `<body>` section **must** include (replacing <APP_ID> with your PX App ID, and <APP_ID_WITH_NO_PX_PREFIX> with your PX App ID without 'PX' in its beginning):


```html
<script>
    window._pxAppId = '<APP_ID>';
    window._pxJsClientSrc = '<APP_ID_WITH_NO_PX_PREFIX>/init.js';
    window._pxHostUrl = '<APP_ID_WITH_NO_PX_PREFIX>/xhr';
    window._pxFirstPartyEnabled = true;
</script>
<script src="/<APP_ID_WITH_NO_PX_PREFIX>/captcha/recaptcha.js"></script>
```
* In the HTML structure, the `<body>` section must include the following line where the Captcha element is to be located:

```
<div id="px-captcha"></div>
```

2. Set the `_M.custom_block_url` to the location you have just defined (e.g. /block.html)
3. Set the `_M.captcha_provider` parameter to `reCaptcha`
4. Set the `_M.redirect_on_custom_url` flag to **false**.
5. Change the `<APP_ID>` placeholder on the block.html page to the Application ID provided on the PerimeterX Portal.


You are now Blocking requests providing a CAPTCHA to the user for cleanup.

###Redirecting to a Custom Block Page
Instead of rendering the block page under the current URL, you can have the Enforcer redirect the blocked request to a different URL by setting `_M.redirect_on_custom_url` to **true**.