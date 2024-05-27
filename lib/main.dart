import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:flutter_cors/flutter_cors.dart';
import 'package:http_proxy/http_proxy.dart';
void main() {
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Demo App'),
    );
  }
}



Future<void> fetchPosts() async {
  final response = await http.get(Uri.parse('https://post-api-omega.vercel.app/api/posts?page=1'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print(data); // array of posts
    data.forEach((post) {
      print(post['title']); // print the title of each post
      // you can access other properties of the post object here
    });
  } else {
    throw Exception('Failed to load posts');
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
   Future<List<dynamic>>? _postsFuture;

    startProxyServer() async {
     final proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

     print('Proxy server listening on ws://localhost:${proxyServer.port}');

     await for (HttpRequest request in proxyServer) {
       final uri = Uri.parse(request.uri.toString());
       final targetUrl = Uri.parse('https://post-api-omega.vercel.app${uri.path}');

       final targetRequest = http.Request(request.method, targetUrl);
       final headers = <String, String>{};
       request.headers.forEach((name, values) {
         headers[name] = values.first;
       });
       targetRequest.headers.addAll(headers);

       if (request.method == 'POST' || request.method == 'PUT') {
         targetRequest.body = await request.transform(utf8.decoder as StreamTransformer<Uint8List, dynamic>).join();
       }

       final targetResponse = await http.Client().send(targetRequest);

       targetResponse.headers.forEach((name, values) {
         for (final value in values.split(',')) {
           request.response.headers.add(name, value.trim());
         }
       });

       request.response.statusCode = targetResponse.statusCode;

       await targetResponse.stream.transform(utf8.decoder).pipe(request.response as StreamConsumer<String>);
       await request.response.close();
     }
   }
   @override
   void initState(){
     super.initState();
     try {
       _postsFuture = fetchPosts();
     } catch (e) {
       print(e);
     }
   }


   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            // Implement your menu action here
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // Implement your notification action here
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          print('Snapshot: $snapshot');
          print('_postsFuture: $_postsFuture');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Your existing widgets here
                  // For each post in the snapshot, create a card with the post details
                  for (var post in snapshot.data!)
                    PostCard(
                      profileName: post['profileName'],
                      profileUsername: post['profileUsername'],
                      imageUrl: post['imageUrl'],
                      content: post['content'],
                      likes: post['likes'],
                      comments: post['comments'],
                    ),
                ],
              ),
            );
          } else {
            return Center(child: Text('No data found'));
          }
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home_outlined, color: Colors.white),
              onPressed: () {
                // Handle Feed action
              },
            ),
            IconButton(
              icon: Icon(Icons.favorite_outline, color: Colors.white),
              onPressed: () {
                // Handle Liked action
              },
            ),
            IconButton(
              icon: Icon(Icons.people_outline, color: Colors.white),
              onPressed: () {
                // Handle Community action
              },
            ),
            IconButton(
              icon: Icon(Icons.bookmark_outline, color: Colors.white),
              onPressed: () {
                // Handle Saved action
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String profileName;
  final String profileUsername;
  final String imageUrl;
  final String content;
  final int likes;
  final int comments;

  const PostCard({
    required this.profileName,
    required this.profileUsername,
    required this.imageUrl,
    required this.content,
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.0,
                  backgroundColor: Colors.red,
                  child: Text(profileName.isNotEmpty ? profileName[0] : '', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profileName, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(profileUsername, style: TextStyle(fontSize: 12.0)),
                  ],
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Image
          Container(
            height: 200.0,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover) : SizedBox.shrink(),
          ),

          // Content
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(content),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.thumb_up_alt_outlined),
                  onPressed: () {},
                ),
                Text('$likes Like'),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.comment_outlined),
                  onPressed: () {},
                ),
                Text('$comments Comment'),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.share_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
