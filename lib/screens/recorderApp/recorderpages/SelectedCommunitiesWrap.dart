import 'package:auditory/SelectedCommunitiesProvider.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auditory/utilities/SizeConfig.dart';

class CommunitiesWrapper extends StatefulWidget {
  @override
  _CommunitiesWrapperState createState() => _CommunitiesWrapperState();
}

class _CommunitiesWrapperState extends State<CommunitiesWrapper> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    var selectedCommunities = Provider.of<SelectedCommunityProvider>(context);
    print(selectedCommunities.selectedCommunities.length);
    print('here');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "Selected Communities: ",
          style: TextStyle(
             // color: Colors.white,
              fontSize: SizeConfig.safeBlockHorizontal * 3),
        ),
        Wrap(
          spacing: 5,
          alignment: WrapAlignment.center,
          children: [
            for (var v in selectedCommunities.selectedCommunities)
              Chip(
                backgroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                deleteIconColor: Colors.grey,
                onDeleted: () {
                  setState(() {
                    selectedCommunities.selectedCommunities.remove(v);
                  });
                },
                label: Text(
                  '${v['name']}',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: SizeConfig.safeBlockHorizontal * 3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
