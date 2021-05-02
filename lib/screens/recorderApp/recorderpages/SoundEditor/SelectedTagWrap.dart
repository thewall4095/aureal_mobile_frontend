
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'SelectedTagProvider.dart';

class SelectTagWrapper extends StatefulWidget {
  @override
  _SelectTagWrapperState createState() => _SelectTagWrapperState();
}

class _SelectTagWrapperState extends State<SelectTagWrapper> {
  @override
  Widget build(BuildContext context) {
    var selectedCommunities = Provider.of<SelectedTagProvider>(context);
    print(selectedCommunities.selectedTag.length);
    print('here');
    return Wrap(
      spacing: 5,
      alignment: WrapAlignment.center,
      children: [
        for (var v in selectedCommunities.selectedTag)
          Chip(
            backgroundColor: Colors.blueAccent,
            shadowColor: Colors.transparent,
            elevation: 0,
            deleteIconColor: Colors.white,
            onDeleted: () {
              setState(() {
                selectedCommunities.selectedTag.remove(v);
              });
            },
            label: Text(
              '${v['name']}',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
