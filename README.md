# Demo App

_Simple tvOS App to showcase FairPlay Encryption_

## Warning/Notes

This demo app does use the old `AVAssetResourceLoaderDelegate` approach. There is also a newer [AVContentKeySession](https://developer.apple.com/documentation/avfoundation/avcontentkeysession) approach. You find a Demo of it in Apples [FairPlay Streaming Server SDK](https://developer.apple.com/services-account/download?path=/Developer_Tools/FairPlay_Streaming_Server_SDK/FairPlay_Streaming_Server_SDK_4.4.zip).

Due to the scope of the bachelor thesis, the `getAuthToken` method is unimplemented. It is quite straigthforward to implement though…

## Building/Running

Just run it like any Xcode project… There are two schemes, one for localhost communication and one for remote URLs.

If you don't want to type an URL on the Apple TV Remote every time, you can provide the app with a default URL in `ViewController.swift` in the `viewDidLoad()` method.

You can specify your remote server URLs in `Default.xcconfig`.

## Linting
The project is set up with [pre-commit](https://pre-commit.com/#install).

To activate it for a project run:
```shell
pre-commit install
```

The next time you commit, it is going to lint and check your files. Sometimes you need to review the changes and do the commit again. If you want to commit without checks
```shell
git commit --no-verify
```