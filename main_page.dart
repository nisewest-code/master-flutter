import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:master_flutter/models/JsonItem.dart';
import 'package:master_flutter/models/content_type.dart';
import 'package:master_flutter/models/json_item_content.dart';
import 'package:master_flutter/pages/list_page.dart';
import 'package:master_flutter/pages/shop_page.dart';
import 'package:master_flutter/utils/download_util.dart';
import 'package:master_flutter/utils/flavors.dart';
import 'package:master_flutter/utils/purchase_util.dart';
import 'package:master_flutter/utils/shared_preference_util.dart';
import 'package:master_flutter/widgets/bottom_navigation_bar.dart';
import 'package:master_flutter/widgets/burger_widget.dart';
import 'package:master_flutter/widgets/button_main_widget.dart';
import 'package:master_flutter/widgets/content_main_widget.dart';
import 'package:master_flutter/widgets/subs_dialog.dart';
import 'package:package_info/package_info.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n.dart';

import '../utils/list_util.dart';
import '../utils/storage_util.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final ContentType contentType = FlavorConfig.instance.values.contentType;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<JsonItem> _items = [];
  // List<String> _categories = [];
  List<ContentCategory> _categoryItems = [];
  List<JsonItem> _sliderItems = [];
  int balance = 0;

  @override
  void initState() {
    refreshSliders();
    refresh();
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    super.initState();
    if (PurchaseUtil.premiumType == PremiumType.NONE)
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showDialog());
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // await Purchases.setDebugLogsEnabled(true);
    await Purchases.setup(FlavorConfig.instance.values.apiKey);
  }

  void refreshSliders() async {
    List<JsonItem> result = await DownloadUtil.loadItemsSlider();
    result.forEach((element) {
      element.imageLink = StorageUtil.checkUrlPrefix(element.imageLink);
    });
    _sliderItems = result;
    setState(() {
    });
  }

  void updateBalance() async {
    int _balance = await SharedPreferenceUtil.getBalance();
    setState(() {
      balance = _balance;
    });
  }
  void refresh() async {
    updateBalance();
    _categoryItems = widget.contentType.contentCategory;
    List<JsonItem> result = await DownloadUtil.downloadJsonArrayToPremium(
        StorageUtil.checkUrlPrefix(
            "/data/content/" + FlavorConfig.instance.values.baseUrl));
    _items = result.sublist(0, 10);
    // Set<String> categories = Set();
    // result.forEach((item) => categories.addAll((item as JsonItemContent)
    //     .category
    //     .replaceAll(" ", "")
    //     .toUpperCase()
    //     .split(",")
    //     .toList()));
    // categories.remove("");
    // _categories = categories.toList();

    setState(() {});
  }

  _showDialog() async {
    showDialog(
        context: context,
        builder: (ctx) =>  SubsDialog()).then((value) {
          setState(() {
            updateBalance();
          });
    });
  }

  @override
  Widget build(BuildContext context) {
        // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    Future<void> _share() async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      await Share.share(FlavorConfig.instance.name +
          "\nDownload it in the app " +
          "\nhttps://play.google.com/store/apps/details?id=" +
          packageInfo.packageName);
    }

    Future<void> _rate() async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      RateMyApp rateMyApp = RateMyApp(
        preferencesPrefix: 'rateMyApp_',
        minDays: 0,
        minLaunches: 0,
        remindDays: 7,
        remindLaunches: 10,
        googlePlayIdentifier: packageInfo.packageName,
      );
      await rateMyApp.init();
      if (mounted && rateMyApp.shouldOpenDialog) {
        rateMyApp.showRateDialog(context,
            title: S.of(context).rate_this_app,
            message: S.of(context).rate_description,
          rateButton: S.of(context).rate_btn_rate,
          noButton: S.of(context).rate_btn_no,
          laterButton: S.of(context).rate_btn_latter,);
      }
    }

    Future<void> _openContent(String data) async {
      if (Platform.isAndroid) {
        AndroidIntent intent = AndroidIntent(
          action: 'action_view',
          data: data,
        );
        await intent.launch();
      }
    }

    _launchURL(String url) async {
      if (await canLaunch(url)) {
        await launch(url, forceWebView: true);
      } else {
        throw 'Could not launch $url';
      }
    }

    return Scaffold(
        drawer: Drawer(
          elevation: 16.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(FlavorConfig.instance.name),
                accountEmail: Text("itgarage.mobile@gmail.com"),
                currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Image.asset("assets/logo.png")),
              ),
              GestureDetector(
                  child: ListTile(
                    title: new Text(S.of(context).rate),
                    leading: new Icon(Icons.star),
                  ),
                  onTap: () => {_rate()}),
              GestureDetector(
                  child: ListTile(
                    title: new Text(S.of(context).shop),
                    leading: new Icon(Icons.shop),
                  ),
                  onTap: () => {Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (BuildContext context) => ShopPage()))
                  .then((val) {
                    if (val != null)
                      updateBalance();
                    setState(() {
                    });
                  })}),
              // GestureDetector(
              //   child: ListTile(
              //         title: new Text(S.of(context).support),
              //         leading: new Icon(Icons.mail),
              //       ),
              //     onTap: () => {
              //       _launchURL("itgarage.mobile@gmail.com")
              //     }),
              Divider(
                height: 0.1,
              ),
              GestureDetector(
                  child: ListTile(
                    title: new Text(S.of(context).share),
                    leading: new Icon(Icons.share),
                  ),
                  onTap: () => {_share()})
            ],
          ),
        ),
        body: SingleChildScrollView(
            child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      "#2E323D".toColor(),
                      "#191D28".toColor(),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(children: [
                      BurgerWidget(Icon(Icons.menu), (context) {
                        Scaffold.of(context).openDrawer();
                      }),
                      Text(
                        balance.toString()+" "+S.of(context).coins,
                        style: TextStyle(fontSize: 22),
                      ),
                    ],),

                    Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(bottom: 20),
                      child: Text(
                        S.of(context).our_products,
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                    Container(
                        margin: EdgeInsets.only(
                            top: 0, bottom: 5, left: 15, right: 15),
                        decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: "#FFFFFF".toColor().withOpacity(0.2),
                                blurRadius: 9,
                                offset: Offset(-5, -5),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.125),
                                blurRadius: 9,
                                offset: Offset(10, 10),
                              )
                            ],
                            gradient: LinearGradient(
                                tileMode: TileMode.clamp,
                                begin: Alignment(-1.0, -1.0),
                                end: Alignment(0.2, 0.2),
                                colors: [
                                  "#1C1F2A".toColor(),
                                  "#2A2D38".toColor()
                                ])),
                        child: Container(
                            margin: EdgeInsets.only(
                                top: 5, bottom: 5, left: 5, right: 5),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  "#2F323D".toColor(),
                                  "#191C27".toColor(),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CarouselSlider(
                              options: CarouselOptions(
                                viewportFraction: 1.0,
                                enlargeCenterPage: false,
                                autoPlay: true,
                              ),
                              items: _sliderItems
                                  .map(
                                    (item) => GestureDetector(
                                        child: CachedNetworkImage(
                                          imageUrl: item.imageLink,
                                          placeholder: (context, url) =>
                                              CircularProgressIndicator(),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.error),
                                          fit: BoxFit.fill,
                                        ),
                                        onTap: () async {
                                          _openContent((item as JsonItemContent).fileLink);
                                        }),
                                  )
                                  .toList(),
                            ))),
                    Container(
                        margin: EdgeInsets.only(
                            top: 40, bottom: 40, left: 15, right: 15),
                        child: ListView.builder(
                          // categories List
                          shrinkWrap: true,
                          itemCount: _categoryItems.length,
                          controller:
                              new ScrollController(keepScrollOffset: false),
                          itemBuilder: (BuildContext context, int position) {
                            return GestureDetector(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20.0),
                                  ),
                                ),
                                child: CachedNetworkImage(
                                  height: 200,
                                  imageUrl: StorageUtil.checkUrlPrefix("${_categoryItems[position].link}"),
                                  placeholder: (context, url) => Image.asset(
                                      "assets/empty_image.png",
                                      width: MediaQuery.of(context).size.width,
                                      fit: BoxFit.fitWidth),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              onTap: () =>{
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            ListPage(_categoryItems[position].name)))
                              },
                            );
                          },
                        )),
                    Container(
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.125),
                                blurRadius: 0.9,
                                offset: Offset(-5, -5),
                              ),
                              BoxShadow(
                                color: "#FFFFFF".toColor().withOpacity(0.2),
                                blurRadius: 9,
                                offset: Offset(0, 2),
                              ),
                            ],
                            gradient: LinearGradient(
                                tileMode: TileMode.clamp,
                                begin: Alignment(-1.0, -1.0),
                                end: Alignment(0.2, 0.2),
                                colors: [
                                  "#2A2D38".toColor(),
                                  "#1C1F2A".toColor(),
                                ])),
                        child: Container(
                            height: 200,
                            margin: EdgeInsets.only(
                                top: 5, bottom: 5, left: 0, right: 0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  "#191C27".toColor(),
                                  "#2F323D".toColor(),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ListView.builder(
                                    itemCount: _items.length,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder:
                                        (BuildContext context, int position) {
                                      return ContentMainWidget(
                                          _items[position]);
                                    })))
                  ],
                ))));
  }

  Widget getWidget() {}

    // try {
    //   await platform
    //       .invokeMethod('installContent', [file.toString()]);
    //   print('Wallpaer Updated.... ');
    // } on PlatformException catch (e) {
    //   print("Failed to Set Wallpaer: '${e.message}'.");
    // }
}
