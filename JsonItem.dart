import 'package:master_flutter/utils/purchase_util.dart';

enum TypePaid {
  FREE,
  VIDEO,
  PAID
}
class JsonItem {
  int id;
  String type;
  String imageLink;
  String name;
  int price;

  JsonItem(id, type, imageLink, name, price){
    this.id = id;
    this.type = type;
    this.imageLink = imageLink;
    this.name = name;
    this.price = price*1;
  }

  factory JsonItem.fromJson(int id, dynamic json) {
    return JsonItem(id, json['id'] as String, json['image_link'] as String,
    json['name'] as String, json['price'] as int ?? 0);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = type;
    data['image_link'] = imageLink;
    data['name'] = name;
    data['price'] = price;
    return data;
  }

  TypePaid getTypePaid(){
    int _price = price == 0 ? 1 : price;
    if (PurchaseUtil.premiumType == PremiumType.PREMIUM)
      return TypePaid.FREE;
    else if (PurchaseUtil.premiumType == PremiumType.SILVER) {
      if (_price == 0)
        return TypePaid.FREE;
      _price = _price ~/ 2;
    }
    if (_price > 0){
      // if (price>25)
      //   return TypePaid.PAID;
      // else
      //   return TypePaid.VIDEO;
        return TypePaid.PAID;
    } else
      return TypePaid.FREE;
  }

  @override
  String toString() {
    return '{ ${this.type}, ${this.imageLink}, ${this.name}}';
  }
}
