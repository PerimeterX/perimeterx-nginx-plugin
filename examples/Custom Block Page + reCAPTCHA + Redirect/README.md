reCATPCHA Example 
-----------------
> This folder contains an example of a reCAPTCHA implementation. The original PerimeterX reCAPTCHA page has been customized, with a different color background, some icons and some colored texts.

In order to use the example:

1. Create a block.html file in your application (or copy the one in this folder), and define a route for it in your nginx.conf file.
2. Set the `_M.custom_block_url` to the location you have just defined (e.g. /block.html)
3. Set the `_M.captcha_enabled` flag to **true**
4. Set the `_M.redirect_on_custom_url` flag to **true** 
5. Change the `<APP_ID>` placeholder on the block.html page to the Application ID provided on the PerimeterX Portal.


You are now Blocking requests providing a CAPTCHA to the user for cleanup.

>Note: Please notice when using redirects, several elements must be included in your HTML file.

When captcha is enabled, and `_M.redirect_on_custom_url` is set to **true**, the block page **must** include the following:

* The `<head>` section **must** include:

```html
<script src="https://www.google.com/recaptcha/api.js"></script>
<script>
function handleCaptcha(response) {
    var vid = getQueryString("vid"); // getQueryString is implemented below
    var uuid = getQueryString("uuid");
    var name = '_pxCaptcha';
    var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString();
    var cookieParts = [name, '=', response + ':' + vid + ':' + uuid, '; expires=', expiryUtc, '; path=/'];
    document.cookie = cookieParts.join('');
    var originalURL = getQueryString("url");
    var originalHost = window.location.host;
    window.location.href = window.location.protocol + "//" +  originalHost + originalURL;
}

// for reference : http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript

function getQueryString(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
            results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    if(name == "url") {
      results[2] = atob(results[2]); //Not supported on IE Browsers
    }
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}
</script>
```
* The `<body>` section **must** include:

```
<div class="g-recaptcha" data-sitekey="6Lcj-R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b" data-callback="handleCaptcha" data-theme="dark"></div>
```

* And the [PerimeterX Javascript snippet](https://console.perimeterx.com/#/app/applicationsmgmt) (availabe on the PerimeterX Portal via this link) must be pasted in.





