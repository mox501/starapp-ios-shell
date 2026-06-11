# StarApp iOS Shell

Modern WKWebView iOS shell template for StarApp.

The GitHub Actions workflow builds an unsigned iOS app bundle and packages it as `newipa-modern.zip` with this structure:

```text
Payload/StarAppShell.app/...
```

Download the workflow artifact and place it in the StarApp project at:

```text
static/pack/webview/newipa-modern.zip
```

The PHP packer then replaces app name, bundle id, version, config, app icon, splash image, ATS, and language-specific strings.
