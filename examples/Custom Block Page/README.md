Block Page Example 
-----------------
> This folder contains an example of a Block Page implementation. The original PerimeterX block page has been customized, with a different color background, some icons and some colored texts.

In order to use the example:

1. Create a block.html file in your application (or copy the one in this folder), and define a route for it in your nginx.conf file.
2. Set the `_M.custom_block_url` to the location you have just defined (e.g. /block.html)
3. Set the `_M.captcha_enabled` flag to **false**
4. Set the `_M.redirect_on_custom_url` flag to **false** 
5. Change the `<APP_ID>` placeholder on the block.html page to the Application ID provided on the PerimeterX Portal.


You are now Blocking requests without providing a CAPTCHA.