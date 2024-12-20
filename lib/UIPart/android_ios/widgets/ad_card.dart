import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:resell/UIPart/android_ios/model/item.dart';

class AdCard extends ConsumerWidget {
  final int cardIndex;
  final Item ad;
  final bool isSold;
  final void Function(Item item)? adSold;
  const AdCard(
      {required this.cardIndex,
      required this.ad,
      required this.adSold,
      required this.isSold,
      super.key});

  String getDate(Timestamp timeStamp) {
    DateTime dateTime = timeStamp.toDate();
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  Widget getWidget(BuildContext context, WidgetRef ref) {
    return Expanded(
      flex: 4,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              if (Platform.isIOS) {
                showCupertinoDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    return CupertinoAlertDialog(
                      title: Text(
                        'Alert',
                        style: GoogleFonts.lato(),
                      ),
                      content: Text(
                        'Is this Item Sold?',
                        style: GoogleFonts.lato(),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(
                            'No',
                            style: GoogleFonts.lato(),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                        ),
                        CupertinoDialogAction(
                          child: Text('Yes',
                              style: GoogleFonts.lato(
                                color: CupertinoColors.destructiveRed,
                              )),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            adSold!(ad);
                          },
                        ),
                      ],
                    );
                  },
                );
              } else if (Platform.isAndroid) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    return AlertDialog(
                      title: Text(
                        'Alert',
                        style: GoogleFonts.lato(),
                      ),
                      content: Text(
                        'Is this Item Sold?',
                        style: GoogleFonts.lato(),
                      ),
                      actions: [
                        TextButton(
                          child: Text(
                            'No',
                            style: GoogleFonts.lato(color: Colors.blue),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Yes',
                              style: GoogleFonts.lato(
                                color: Colors.red,
                              )),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            adSold!(ad);
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: const Color.fromARGB(255, 14, 127, 248),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.check_mark_circled
                          : Icons.check_circle_outline,
                      size: 25,
                      color: Platform.isAndroid ? Colors.blue : null,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Mark this Product as Sold',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: 0.75,
          color: const Color.fromARGB(255, 200, 179, 172),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: isSold ? 3 : 2,
            child: Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: ad.images[0],
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                              placeholder: (context, url) {
                                return ClipRRect(
                                  child: Image.asset(
                                    'assets/images/placeholder.jpg',
                                  ),
                                );
                              },
                              errorWidget: (context, url, error) {
                                return Center(
                                  child: Platform.isIOS
                                      ? const Icon(
                                          CupertinoIcons.exclamationmark_circle)
                                      : const Icon(Icons.error_outline),
                                );
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  ad.adTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                    fontSize: Platform.isIOS ? 18 : 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹ ${ad.price.toInt()}',
                                  style: GoogleFonts.lato(
                                    fontSize: Platform.isIOS ? 20 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                !isSold ? getWidget(context, ref) : const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
