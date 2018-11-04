## <a name="first_party_prefix"></a>Setting Up A First Party Prefix

In some cases you may need to define a prefix to the Enforcer's First-Party routes. The custom prefix must be defined both in the Enforcer's config file and in the PerimeterX console.

To define the First-Party Prefix: 

1. In your `pxconfig.lua` file, set the `_M.first_party_prefix` property to the desired prefix value. For example:

```lua
_M.first_party_prefix = 'resources'
```

2. Open the [PerimeterX Console](https://console.perimeterx.com).

3. Go to `Admin` -> `Applications`.

4. Open the `Snippet` section. Activate `First-Party` (if not in First-Party already), and click `Edit` next to the **Copy Snippet** button.

5. In the pop-up that opens there are two routes beginning with `/<appId without PX>`. Copy both routes to a side document to use in the next steps.

6. Click `Advanced Configuration`.

7. Under **Sensor**, copy the first route from step 5 and add the prefix you added in step 1 to the beginning of of the route.</br>For example: `/resources/<appId without PX>/init.js`

8. Under **Server** copy the second route from step 5 and the prefix you added in step 1 to the beginning of the route.
</br>For example: `/resources/<appId without PX>/xhr`

9. Click `Save Changes`.

10. Click `Copy Snippet` and update the JS Sensor snippet of your site with the updated one.



