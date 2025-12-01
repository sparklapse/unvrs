> This is a placeholder for the [Chromium Content API](https://chromium.googlesource.com/chromium/src/+/HEAD/content/public/README.md).

There is no plan to implement this currently but is here to state some intention. For now use the CEF backend if you need a solid and consistent webview on desktop platforms.

The goal would be to create a set of APIs that would truly allow for simply and quickly creating custom desktop browsers (and maybe android). Some key features could include:
- Simplified build process and cross platform builds
- Applying patches (like ungoogled chromium)
- Creating custom js APIs and extensions
- Creating custom rendering in combination with other APIs (eg. native, skia, bgfx, etc.)

A lot these features can already be provided pretty reliably through CEF so there would need to be a good reason to switch to the CCAPI.
Adding this would be for the intention of creating a browser builder SDK, since if all you need is to develop a webapp or display some limited web content, then CEF or native platform webviews will be quicker to integrate and have more straight forward APIs.
