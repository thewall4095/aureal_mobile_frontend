import 'package:auditory/FilterState.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'TagSearch.dart';

class SortFilter extends StatefulWidget {
  @override
  _SortFilterState createState() => _SortFilterState();
}

class _SortFilterState extends State<SortFilter> {
  void storeLocalData(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('sort', value);
  }

  @override
  Widget build(BuildContext context) {
    var filterObject = Provider.of<SortFilterPreferences>(context);
    SizeConfig().init(context);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ListTile(
            title: Text(
              'SORT',
              textScaleFactor: 0.75,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeConfig.safeBlockHorizontal * 4),
            ),
            trailing: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Column(
                  children: [
                    ListTile(
                        onTap: () {
                          print('High to low');

                          filterObject.sort = null;
                          print(filterObject.sort);
                          storeLocalData(filterObject.sort);
                        },
                        leading: Icon(
                          Icons.sort,
                          color: kActiveColor,
                        ),
                        trailing: filterObject.sort == null
                            ? Icon(
                                Icons.check,
                                color: kActiveColor,
                              )
                            : SizedBox(
                                width: 0,
                              ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Listeners (High to Low)",
                              textScaleFactor: 0.75,
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                  color: Colors.white),
                            ),
                            Text(
                              "Show podcasts based on number of listens",
                              textScaleFactor: 0.75,
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 3,
                                  color: Colors.grey),
                            )
                          ],
                        )),
                    ListTile(
                      onTap: () {
                        print('Recommended Selected');

                        filterObject.sort = 'recommendations';
                        print(filterObject.sort);
                        storeLocalData(filterObject.sort);
                      },
                      leading: Icon(
                        Icons.scatter_plot,
                        color: kActiveColor,
                      ),
                      trailing: filterObject.sort != null
                          ? Icon(
                              Icons.check,
                              color: kActiveColor,
                            )
                          : SizedBox(
                              width: 0,
                            ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Recommended for you",
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 4,
                                color: Colors.white),
                          ),
                          Text(
                            'Show the most relevant podcast based on your viewing history',
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 3,
                                color: Colors.grey),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
