import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AudioEditor extends StatefulWidget {
  var episodeObject;

  AudioEditor({ this.episodeObject});

  @override
  _AudioEditorState createState() => _AudioEditorState();
}

class _AudioEditorState extends State<AudioEditor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.episodeObject['image'],
                      imageBuilder: (context, imageProvider) {
                        return Container(
                          height: MediaQuery.of(context).size.width / 5,
                          width: MediaQuery.of(context).size.width / 5,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: imageProvider, fit: BoxFit.cover)),
                        );
                      },
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${widget.episodeObject['name']}",
                              maxLines: 2,
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 4),
                            ),
                            Text("${widget.episodeObject['podcast_name']}")
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
