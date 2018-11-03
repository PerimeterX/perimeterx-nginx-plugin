## <a name="first_party_prefix"></a>Setting Up A First Party Prefix

In some cases you may need to define a prefix to the enforcer's first-party routes. The process of defining the custom prefix is done on both the enforcer's config file and the PerimeterX console. 

1. In your `pxconfig.lua` file, set the `_M.first_party_prefix` property to the desired prefix value. For example:

```lua
_M.first_party_prefix = 'resources'
```

2. Head to the [PerimeterX Console](https://console.perimeterx.com).

3. Click `Admin` and then `Applications`.

4. Click `Snippet`. Move the slider to `First-Party` if its not already there. Click the `Edit` button.

5. On the modal that opens you'll see two routes starting with `/<appId without PX>`. Copy both to a side document as we will use them in the next steps.

6. Click `Advanced Configuration`.

7. Under **Sensor** copy the first route from step 5 and add the same prefix you added in step 1 at the beginning of it. For example `/resources/<appId without PX>/init.js`

8. Under **Server** copy the second route from step 5 and add the same prefix you added in step 1 at the beginning of it. For example `/resources/<appId without PX>/xhr`

9. Click `Save Changes`.

10. Click `Copy Snippet` and update the JS sensor snippet of your site with the updated one.



