funCAPTCHA Example 
-----------------
> This folder contains an example of a funCAPTCHA implementation. The original PerimeterX funCAPTCHA page has been customized, with a different color background, some icons and some colored texts.

In order to use the example:

1. Create a block.html file in your application (or copy the one in this folder), and define a route for it in your nginx.conf file.
2. Set the `_M.custom_block_url` to the location you have just defined (e.g. /block.html)
3. Set the `_M.captcha_enabled` flag to **true**
4. Set the `_M.captcha_provider` parameter to `funCaptcha`
5. Set the `_M.redirect_on_custom_url` flag to **true** 
6. Change the `<APP_ID>` placeholder on the block.html page to the Application ID provided on the PerimeterX Portal.


You are now Blocking requests providing a CAPTCHA to the user for cleanup.

>Note: Please notice when using redirects, several elements must be included in your HTML file.

When captcha is enabled, and `_M.redirect_on_custom_url` is set to **true**, the block page **must** include the following:

* The `<head>` section **must** include:

```html
<script src="https://www.google.com/recaptcha/api.js"></script>
<script>
function loadFunCaptcha() {
            var vid = getQueryString("vid");
            var uuid = getQueryString("uuid");
            var delimiter = '|,|';

            new FunCaptcha({
                public_key: "19E4B3B8-6CBE-35CC-4205-FC79ECDDA765",
                target_html: "CAPTCHA",
                callback: function () {
                    var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString();
                    var pxCaptcha = "_pxCaptcha=" + btoa(JSON.stringify({r: document.getElementById("FunCaptcha-Token").value, u: uuid, v: vid}));
              
                    var cookieParts = [
                        pxCaptcha,
                        "; expires=",
                        expiryUtc,
                        "; path=/"
                    ];

                    document.cookie = cookieParts.join("");
                    location.reload();
                }
            });
        }

        function getQueryString(name, url) {
            if (!url) url = window.location.href;
            name = name.replace(/[\[\]]/g, "\\$&");
            var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
                results = regex.exec(url);
            if (!results) return null;
            if (!results[2]) return '';
            results[2] = decodeURIComponent(results[2].replace(/\+/g, " "));
            if(name === "url") {
                results[2] = atob(results[2]);
            }
            return results[2];
        }
</script>
```
* The `<body>` section **must** include:

```
<div id="CAPTCHA"></div>
```

* And the [PerimeterX Javascript snippet](https://console.perimeterx.com/#/app/applicationsmgmt) (availabe on the PerimeterX Portal via this link) must be pasted in.





