Block Page Example 
-----------------
####This folder contains an example of a Block Page implementation. The original PerimeterX block page has been customized, with a different color background, some icons and some colored texts.

In order to use the contents of this page, first uncomment the `' .. ref_str .. '` part of the html. 

Now all you have to do is create a one liner from the edited html (an easy way is to use an online tool such as [Compress HTML](http://www.textfixer.com/html/compress-html-compression.php)). Place it inside the `ngx_say` function, on the `else` part of the `if px_config.captcha_enabled then`.



###Thats it, you are good to go !




