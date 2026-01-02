# WebView

> NOTE: This will eventually be released as a sepereate package but since the core
> content is still in dev, it's being included for dev speed.

Show web content in your applications.

**Dependencies:**

- cmake

## Usage

**Displaying a WebView**

**Customizing**

Browsers are extremely complicated with many different components you may want to customize. Most modern browsers will sandbox and run different components in different processes/threads meaning from your main application thread, you won't be able to directly access contexts like javascript or rendering. To make this more accessible to develop with, you're able to provide a context struct to directly interact in the threads responsible for each component and send messages back to your main application thread through IPC.
