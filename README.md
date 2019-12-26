# Restio

An HTTP Client for Dart inpired by [OkHttp](http://square.github.io/okhttp/).

### Installation

In `pubspec.yaml` add the following dependency:

```yaml
dependencies:
  restio: ^0.3.0
```

### How to use

1. Create a instance of `Restio`:
```dart
final client = Restio();
```

2. Create a `Request`:
```dart
final request = Request(
    uri: Uri.parse('https://httpbin.org/json'),
    method: 'GET',
);
```

or

```dart
final request = Request.get('https://httpbin.org/json');
```

3. Create a `Call` from `Request`:
```dart
final call = client.newCall(request);
```

4. Execute the `Call` and get a `Response`:
```dart
final response = await call.execute();
```

### Recipes

#### Performing a GET request:

```dart
final client = Restio();
final request = Request.get('https://postman-echo.com/get');
final call = client.newCall(request);
final response = await call.execute();
```

#### Performing a POST request:
```dart
final request = Request.post(
  'https://postman-echo.com/post',
  body: RequestBody.fromString(
    'This is expected to be sent back as part of response body.',
    contentType: MediaType.text,
  ),
);
final call = client.newCall(request);
final response = await call.execute();
```

#### Get response stream:
```dart
final stream = response.body.data;
```

#### Get raw response bytes:
```dart
final bytes = response.body.raw(decompress: false);
final bytes = response.body.compressed();
```

#### Get decompressed response bytes (gzip, deflate or brotli):
```dart
final bytes = response.body.raw(decompress: true);
final bytes = response.body.decompressed();
```

#### Get response string:
```dart
final string = response.body.string();
```

#### Get response JSON:
```dart
final json = response.body.json();
```

#### Sending form data:
```dart
final request = Request.post(
  'https://postman-echo.com/post',
  body: body: FormBody.fromMap({
    'foo1': 'bar1',
    'foo2': 'bar2',
  }),
);
final call = client.newCall(request);
final response = await call.execute();
```

#### Sending multipart data:
```dart
final request = Request.post(
  'https://postman-echo.com/post',
  body: MultipartBody(
    parts: [
      Part.file(
        'file1',
        'upload.txt',
        RequestBody.fromFile(
          File('./upload.txt'),
          contentType: MediaType.text,
        ),
      ),
    ],
  ),
);
final call = client.newCall(request);
final response = await call.execute();
```

#### Posting binary data:
```dart
// Binary data.
final postData = <int>[...];
final request = Request.post(
  'https://postman-echo.com/post',
  body: RequestBody.fromBytes(postData, contentType: MediaType.octetStream),
);
final call = client.newCall(request);
final response = await call.execute();
```

#### Listening for download progress:
```dart
final ResponseProgressListener onProgress = (response, sent, total, done) {
  print('sent: $sent, total: $total, done: $done');
};

final progressClient = client.copyWith(
  onDownloadProgress: onProgress,
);

final request = Request.get('https://httpbin.org/stream-bytes/36001');

final call = client.newCall(request);
final response = await call.execute();
final data = await response.body.raw(false);
```

#### Listening for upload progress:
```dart
final RequestProgressListener onProgress = (request, sent, total, done) {
  print('sent: $sent, total: $total, done: $done');
};

final progressClient = client.copyWith(
  onUploadProgress: onProgress,
);

final request = Request.post('https://postman-echo.com/post',
  body: RequestBody.fromFile(File('./large_file.txt'));
);

final call = client.newCall(request);
final response = await call.execute();
```


#### Pause & Resume retrieving response body data
```dart
final response = await call.execute();
final responseBody = response.body;
final data = await responseBody.raw();

// Called from any callback.
responseBody.pause();

responseBody.resume();
```

#### Interceptors
```dart
final client = Restio(
  interceptors: [MyLogInterceptor()],
);

class MyLogInterceptor implements Interceptor {
  @override
  Future<Response> intercept(Chain chain) async {
    final request = chain.request;
    print('Sending request: $request');
    final response = await chain.proceed(chain.request);
    print('Received response: $response');
    return response;
  }
}
```

#### Authentication
```dart
final client = Restio(
  authenticator: BasicAuthenticator(
    username: 'postman',
    password: 'password',
  ),
);

final request = Request.get('https://postman-echo.com/basic-auth');

final call = client.newCall(request);
final response = await call.execute();
```

> Supports Bearer, Digest and Hawk authorization method too.

#### Cookie Manager
```dart
final client = Restio(
  cookieJar: MyCookieJar(),
);

class MyCookieJar extends CookieJar {

  @override
  Future<List<Cookie>> loadForRequest(Request request) async {
    // TODO:
  }

  @override
  Future<void> saveFromResponse(
    Response response,
    List<Cookie> cookies,
  ) async {
    // TODO:
  }
}
```

#### Handling Errors
```dart
try {
  final response = await call.execute();
} on CancelledException catch(e) {
  // TODO:
} on TooManyRedirectsException catch(e) {
  // TODO:
} on TimedOutException catch(e) {
  // TODO:
} on RestioException catch(e) {
  // TODO:
}
```

#### Cancellation
```dart
final call = client.newCall(request);
final response = await call.execute();

// Cancel the request with 'cancelled' message.
call.cancel('cancelled');
```

#### Proxy
```dart
final client = Restio(
  proxy: Proxy(
    host: 'localhost',
    port: 3001,
  ),
);

final request = Request.get('http://localhost:3000');
final call = client.newCall(request);
final response = await call.execute();
```

#### HTTP2

```dart
final client = Restio(isHttp2: true);
final request = Request.get('https://www.google.com/');
final call = client.newCall(request);
final response = await call.execute();
```

#### WebSocket
```dart
final client = WebSocketClient();
final request = WebSocketRequest.url('wss://echo.websocket.org');
final conn = await client.connect(request);

// Receive.
conn.stream.listen((dynamic data) {
  print(data);
});

// Send.
conn.addString('🎾');

await conn.close();
```

#### DNS

Thanks to [dart-protocol](https://github.com/dart-protocol) for this great [dns](https://github.com/dart-protocol/dns) library!

```dart
final dns = DnsOverUdp.google();
final client = Restio(
  dns: dns,
);

final request = Request.get('https://postman-echo.com/get');
final call = client.newCall(request);
final response = await call.execute();
```

> Supports DnsOverHttps too.

### Projects using this library

* [Restler](https://play.google.com/store/apps/details?id=br.tiagohm.restler): Restler is an Android app built with simplicity and ease of use in mind. It allows you send custom HTTP/HTTPS requests and test your REST API anywhere and anytime.