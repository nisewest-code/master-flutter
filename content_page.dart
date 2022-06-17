import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_intent_plus/android_intent.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:master_flutter/generated/l10n.dart';
import 'package:master_flutter/models/JsonItem.dart';
import 'package:master_flutter/models/json_item_content.dart';
import 'package:master_flutter/utils/purchase_util.dart';
import 'package:master_flutter/utils/shared_preference_util.dart';
import 'package:master_flutter/utils/storage_util.dart';
import 'package:master_flutter/widgets/ads/admob_interstitial_ad.dart';
import 'package:master_flutter/widgets/ads/admob_video_rewarded_ad.dart';
import 'package:master_flutter/widgets/bottom_sheet_widget.dart';
import 'package:master_flutter/widgets/burger_widget.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:master_flutter/widgets/ads/native_ad_widget.dart';
import 'package:rate_my_app/rate_my_app.dart';

// const bool _kAutoConsume = true;
//
// const String _kConsumableId = 'consumable';
// const String _kUpgradeId = 'upgrade';
// const String _kSilverSubscriptionId = 'subscription_silver';
// const String _kGoldSubscriptionId = 'subscription_gold';
// const List<String> _kProductIds = <String>[
//   _kConsumableId,
//   _kUpgradeId,
//   _kSilverSubscriptionId,
//   _kGoldSubscriptionId,
// ];

class ContentPage extends StatefulWidget {
  final JsonItemContent item;
  String title;
  AdmobVideoRewardedAd _admobVideoRewardedAd;
  AdmobInterstitialAd _admobInterstitialAd;
  var isPremium = PurchaseUtil.premiumType == PremiumType.SILVER || PurchaseUtil.premiumType == PremiumType.PREMIUM;

  ContentPage(this.item) {
    _admobVideoRewardedAd = AdmobVideoRewardedAd();
    _admobInterstitialAd = AdmobInterstitialAd();
    _admobVideoRewardedAd.createRewardedAd();
    isPremium = PurchaseUtil.premiumType == PremiumType.SILVER || PurchaseUtil.premiumType == PremiumType.PREMIUM;
    // _admobInterstitialAd.createInterstitialAd();
  }

  @override
  _ContentPageState createState() =>
      _ContentPageState(_admobVideoRewardedAd, _admobInterstitialAd);
}

class _ContentPageState extends State<ContentPage> {
  // final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  // List<String> _notFoundIds = [];
  // List<ProductDetails> _products = [];
  // List<PurchaseDetails> _purchases = [];
  // List<String> _consumables = [];
  // bool _isAvailable = false;
  // bool _purchasePending = false;
  // bool _loading = true;
  // String _queryProductError;
  _ContentPageState(this._admobVideoRewardedAd, this._admobInterstitialAd);

  bool isOpen = false;
  ReceivePort _port = ReceivePort();
  var progress = 0.0;
  var centerWidget;
  var description;
  var taskId;
  var _isBought = false;
  var _isMinecraftInstailed = true;
  AdmobVideoRewardedAd _admobVideoRewardedAd;
  AdmobInterstitialAd _admobInterstitialAd;
  int balance = 0;

  Future<void> checkMinecraftInstailed() async {
    try {
      var result = await platform.invokeMethod('checkMinecraft', []);
      _isMinecraftInstailed = result;
    } on PlatformException catch (e) {
      print("Failed to Set Wallpaer: '${e.message}'.");
    }
    // _isMinecraftInstailed =  await PackageManager.getInstance().isInstall("com.mojang.minecraftpe");
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

  static const platform =
      const MethodChannel('com.itgarage.modsforminecraft/checkMinecraft');

  void _show(BuildContext ctx) async {
     showModalBottomSheet(
        isScrollControlled: true,
        elevation: 5,
        context: ctx,
        builder: (ctx) => Padding(
              padding: EdgeInsets.only(top:10),
              child: Container(
                  height: MediaQuery.of(context).copyWith().size.height * 0.75,
                  child: BottomSheetWidget(widget.item)
            )))
        .then((val) {
          if (val != null)
            onProductBought();
          else
            updateBalance();
          setState(() {

          });
    });
  }

  void onProductBought() async {
    if (await PurchaseUtil.isItemEnough(widget.item)) {
      PurchaseUtil.onItemBought(widget.item);
      updateBalance();
      downloadFile();
    }
  }

  Future<void> _openContent(File file) async {
    var uri = file.path;
    // FileProvider.getUriForFile(this, this.getApplicationContext().getPackageName() + ".provider", file)
    if (Platform.isAndroid) {

      // intent.setType("file/*");
      // intent.putExtra("android.intent.extra.STREAM", uri);
      // intent.setDataAndType(uri, "file/*");
      // AndroidIntent intent = AndroidIntent(
      //   action: 'action_view',
      //   data: "minecraft://?=import=$uri",
      // );

      // AndroidIntent intent = AndroidIntent(
      //   action: 'action_send',
      //   // data: "minecraft://?=import=$uri",
      //   arguments: <String, dynamic>{
      //     'android.intent.extra.STREAM': uri
      //   },
      //   flags: [268435457]
      // );
      // await intent.launch();
    }

    try {
      var result = await platform
          .invokeMethod('openContent', [uri]);
      if (!result){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).minecraft_not_installed),
        ));
      }
      print('Wallpaer Updated.... ');
    } on PlatformException catch (e) {
      print("Failed to Set Wallpaer: '${e.message}'.");
    }
  }

  @override
  void initState() {
    super.initState();
    refresh();
    // checkMinecraftInstailed();
    _admobVideoRewardedAd.setOnRewardedListener(() {
      setState(() {
        // _isBought = true;
        centerWidget = getButtonWidget();
      });
    });
    _bindBackgroundIsolate();

    // final Stream<List<PurchaseDetails>> purchaseUpdated =
    //     _inAppPurchase.purchaseStream;
    // initStoreInfo();

    // IsolateNameServer.registerPortWithName(
    //     _port.sendPort, 'downloader_send_port');
    // _port.listen((dynamic data) {
    //   taskId = data[0];
    //   DownloadTaskStatus status = data[1];
    //   var progress = 0.0;
    //   print(progress);
    //   if (status == DownloadTaskStatus.running) {
    //     progress = data[2];
    //   } else if (status == DownloadTaskStatus.complete) {
    //     progress = 0;
    //   }
    //   setState(() {
    //     this.progress = progress;
    //   });
    // });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  void updateBalance() async{
    int _balance = await SharedPreferenceUtil.getBalance();
    setState(() {
      balance = _balance;
    });
  }

  void refresh() async {
    updateBalance();
    var isBought = await PurchaseUtil.isItemBought(widget.item);
    setState(() {
      _isBought = isBought;
      centerWidget = getButtonWidget();
    });
  }
  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      if (status == DownloadTaskStatus.running) {
        setState(() {
          this.progress = progress / 100;
          centerWidget = progressWidget;
          this.taskId = id;
        });
      } else if (status == DownloadTaskStatus.complete) {
        this.progress = 0;
        isOpen = true;
        setState(() {
          _rate();
          centerWidget = getButtonOpenWidget(isOpen);
        });
      } else if (status == DownloadTaskStatus.canceled) {
        this.progress = 0;
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  // Future<void> initStoreInfo() async {
  //   final bool isAvailable = await _inAppPurchase.isAvailable();
  //   if (!isAvailable) {
  //     setState(() {
  //       _isAvailable = isAvailable;
  //       _products = [];
  //       _purchases = [];
  //       _notFoundIds = [];
  //       _consumables = [];
  //       _purchasePending = false;
  //       _loading = false;
  //     });
  //     return;
  //   }
  //
  //   ProductDetailsResponse productDetailResponse =
  //   await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
  //   if (productDetailResponse.error != null) {
  //     setState(() {
  //       _queryProductError = productDetailResponse.error!.message;
  //       _isAvailable = isAvailable;
  //       _products = productDetailResponse.productDetails;
  //       _purchases = [];
  //       _notFoundIds = productDetailResponse.notFoundIDs;
  //       _consumables = [];
  //       _purchasePending = false;
  //       _loading = false;
  //     });
  //     return;
  //   }
  //
  //   if (productDetailResponse.productDetails.isEmpty) {
  //     setState(() {
  //       _queryProductError = null;
  //       _isAvailable = isAvailable;
  //       _products = productDetailResponse.productDetails;
  //       _purchases = [];
  //       _notFoundIds = productDetailResponse.notFoundIDs;
  //       _consumables = [];
  //       _purchasePending = false;
  //       _loading = false;
  //     });
  //     return;
  //   }
  //
  //   await _inAppPurchase.restorePurchases();
  //
  //   List<String> consumables = await ConsumableStore.load();
  //   setState(() {
  //     _isAvailable = isAvailable;
  //     _products = productDetailResponse.productDetails;
  //     _notFoundIds = productDetailResponse.notFoundIDs;
  //     _consumables = consumables;
  //     _purchasePending = false;
  //     _loading = false;
  //   });
  // }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    if (description == null) {
      description = Container(
          margin:
          EdgeInsets.only(top: 0, bottom: 15, left: 15, right: 15),
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(15.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: "#FFFFFF".toColor().withOpacity(0.045),
                  blurRadius: 0.9,
                  offset: Offset(-6, -6),
                ),
                BoxShadow(
                  color: "#0D111C".toColor().withOpacity(0.125),
                  blurRadius: 0.9,
                  offset: Offset(6, 6),
                )
              ],
              gradient: LinearGradient(
                  tileMode: TileMode.clamp,
                  begin:  Alignment(-1.0, -1.0),
                  end: Alignment(0.2, 0.2),
                  colors: ["#EB9B5A".toColor(),"#F4BF7E".toColor()])
          ),

          child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    "#FFC685".toColor(),
                    "#D38342".toColor(),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(15.0),
                ),
              ),
              margin: EdgeInsets.only(top: 2, bottom: 2, left: 2, right: 2),
              child: RawMaterialButton(
                shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                onPressed: (){
                  setState(() {
                    description = Container(
                      margin: EdgeInsets.only(
                          top: 0, bottom: 15, left: 0, right: 0),
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
                      child: Text(widget.item.description),
                    );
                  });
                },
                child: Text(
                  S.of(context).more_detailed,
                  style: TextStyle(
                      fontSize: 16
                  ),
                ),
              )
          ));
    }
    if (centerWidget == null) centerWidget = getButtonOpenWidget(isOpen);
    return Scaffold(
        body: Container(
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BurgerWidget(Icon(Icons.arrow_back), (context) {
                        Navigator.pop(context);
                      }),
                      Flexible(
                          child: Container(
                        alignment: AlignmentDirectional.centerStart,
                        child: Column(children: [
                          Text(
                            widget.item.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 22),
                          ),
                          Text(
                            balance.toString()+" "+S.of(context).coins,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18),
                          ),
                        ],)

                      )),
                    ],
                  ),
                  Expanded(
                      child: ListView(
                    children: [
                      Container(
                          margin: EdgeInsets.only(
                              top: 10, bottom: 5, left: 15, right: 15),
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
                                  blurRadius: 0.9,
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
                              child: Card(
                                child: CachedNetworkImage(
                                  width: MediaQuery.of(context).size.width,
                                  imageUrl: widget.item.imageLink,
                                  placeholder: (context, url) => Image.asset(
                                      "assets/empty_image.png",
                                      width: MediaQuery.of(context).size.width,
                                      fit: BoxFit.fitWidth),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                  fit: BoxFit.fitWidth,
                                ),
                              ))),
                      centerWidget,
                      description,
                      !widget.isPremium ? NativeAdWidget(): Container()

                      // NativeAdWidget(),
                    ],
                  ))
                ])));
  }

  Widget getButtonOpenWidget(bool isOpen) {
    if (isOpen) {
      return Container(
          margin:
          EdgeInsets.only(top: 0, bottom: 15, left: 15, right: 15),
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(15.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: "#FFFFFF".toColor().withOpacity(0.045),
                  blurRadius: 0.9,
                  offset: Offset(-6, -6),
                ),
                BoxShadow(
                  color: "#0D111C".toColor().withOpacity(0.125),
                  blurRadius: 0.9,
                  offset: Offset(6, 6),
                )
              ],
              gradient: LinearGradient(
                  tileMode: TileMode.clamp,
                  begin:  Alignment(-1.0, -1.0),
                  end: Alignment(0.2, 0.2),
                  colors: ["#7FAE41".toColor(),"#AEDD70".toColor()])
          ),

          child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    "#AEDD70".toColor(),
                    "#7FAE41".toColor(),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(15.0),
                ),
              ),
              margin: EdgeInsets.only(top: 2, bottom: 2, left: 2, right: 2),
              child: RawMaterialButton(
                shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                onPressed: () async{
                  final path = await _localPath;
                  var file = File(path +
                      "/" +
                      widget.item.fileLink
                          .substring(widget.item.fileLink.lastIndexOf("/") + 1));
                  _openContent(file);
                },
                child: Text(
                  S.of(context).open,
                  style: TextStyle(
                      fontSize: 16
                  ),
                ),
              )
          ));
    } else
      return getButtonWidget();
  }

  Widget get progressWidget {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
                child: LinearProgressIndicator(
              value: progress,
            )),
            IconButton(
              icon: Icon(Icons.close),
              iconSize: 30,
              onPressed: () {
                _cancelDownload();
                setState(() {
                  centerWidget = getButtonOpenWidget(false);
                });
              },
            )
          ],
        ));
  }

  Future<String> get _localPath async {
    final directory = await getExternalStorageDirectory();

    return directory.path;
  }

  void _cancelDownload() async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  void downloadFile() async{
    if (!_isMinecraftInstailed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).minecraft_not_installed),
      ));
      return;
    }
    final path = await _localPath;
    var file = File(path);
    bool hasExisted = await Directory(file.path).exists();
    print(hasExisted);
    if (!hasExisted) {
      await file.create(recursive: true);
    }
    var task = await FlutterDownloader.enqueue(
        url: StorageUtil.checkUrlPrefix(widget.item.fileLink),
        savedDir: path,
        fileName: widget.item.fileLink
            .substring(widget.item.fileLink.lastIndexOf("/") + 1),
        showNotification: false,
        openFileFromNotification: false);
    // _admobInterstitialAd.onShow();
  }

  Widget getButtonWidget() {
    void Function() callback;
    String text;
    if (!_isBought) {
      switch (widget.item.getTypePaid()) {
        case TypePaid.FREE:
          text = S.of(context).download;
          callback = () async {
            downloadFile();
          };
          break;
        case TypePaid.VIDEO:
          text = S.of(context).open_for_viewing_ads;
          callback = () {
            _admobVideoRewardedAd.onShow();
          };
          break;
        case TypePaid.PAID:
          text = S.of(context).open_for + PurchaseUtil.getItemPrice(widget.item).toString() + S.of(context).coins;
          callback = () async {
            if (!await PurchaseUtil.isItemEnough(widget.item))
              _show(context);
            else {
              await PurchaseUtil.onItemBought(widget.item);
              updateBalance();
              downloadFile();
            }
          };
          break;
      }
    } else {
      text = S.of(context).download;
      callback = () async {
        if (!_isMinecraftInstailed) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).minecraft_not_installed),
          ));
          return;
        }
        final path = await _localPath;
        var file = File(path);
        bool hasExisted = await Directory(file.path).exists();
        print(hasExisted);
        if (!hasExisted) {
          await file.create(recursive: true);
        }
        var task = await FlutterDownloader.enqueue(
            url: StorageUtil.checkUrlPrefix(widget.item.fileLink),
            savedDir: path,
            fileName: widget.item.fileLink
                .substring(widget.item.fileLink.lastIndexOf("/") + 1),
            showNotification: false,
            openFileFromNotification: false);
        // _admobInterstitialAd.onShow();
      };
    }
    return Container(
        margin:
        EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(15.0),
            ),
            boxShadow: [
              BoxShadow(
                color: "#FFFFFF".toColor().withOpacity(0.045),
                blurRadius: 0.9,
                offset: Offset(-6, -6),
              ),
              BoxShadow(
                color: "#0D111C".toColor().withOpacity(0.125),
                blurRadius: 0.9,
                offset: Offset(6, 6),
              )
            ],
            gradient: LinearGradient(
                tileMode: TileMode.clamp,
                begin:  Alignment(-1.0, -1.0),
                end: Alignment(0.2, 0.2),
                colors: ["#03A5D5".toColor(),"#28CAFA".toColor()])
        ),

        child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  "#35D7FF".toColor(),
                  "#02A4D4".toColor(),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(15.0),
              ),
            ),
            margin: EdgeInsets.only(top: 2, bottom: 2, left: 2, right: 2),
            child: RawMaterialButton(
              shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              onPressed: (){
                callback.call();
              },
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 16
                ),
              ),
            )
        ));
  }
}
