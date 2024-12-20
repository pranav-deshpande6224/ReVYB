import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:resell/Authentication/Providers/internet_provider.dart';
import 'package:resell/Authentication/android_ios/handlers/auth_handler.dart';
import 'package:resell/Authentication/android_ios/screens/login_a_i.dart';
import 'package:resell/UIPart/android_ios/Providers/pagination_active_ads/category_ads_pagination.dart';
import 'package:resell/UIPart/android_ios/Providers/pagination_active_ads/other_ads_pagination.dart';
import 'package:resell/UIPart/android_ios/model/item.dart';
import 'package:resell/UIPart/android_ios/screens/home_android_ios/product_detail_screen_a_i.dart';
import 'package:resell/constants/constants.dart';

class DisplayCategoryAdsAI extends ConsumerStatefulWidget {
  final String categoryName;
  final String subCategoryName;
  const DisplayCategoryAdsAI(
      {required this.categoryName, required this.subCategoryName, super.key});

  @override
  ConsumerState<DisplayCategoryAdsAI> createState() =>
      _DisplayCategoryAdsAIState();
}

class _DisplayCategoryAdsAIState extends ConsumerState<DisplayCategoryAdsAI> {
  late AuthHandler handler;
  final ScrollController categoryAdScrollController = ScrollController();
  void moveToLogin() {
    if (Platform.isAndroid) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const LoginAI()),
          (Route<dynamic> route) => false);
    } else if (Platform.isIOS) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (ctx) => const LoginAI()),
          (Route<dynamic> route) => false);
    }
  }

  @override
  void initState() {
    handler = AuthHandler.authHandlerInstance;
    if (handler.newUser.user == null) {
      moveToLogin();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.categoryName == Constants.other) {
        ref.read(otherAdsprovider.notifier).fetchInitialItems();
      } else {
        ref.read(showCatAdsProvider.notifier).fetchInitialItems(
              widget.categoryName,
              widget.subCategoryName,
            );
      }
    });
    categoryAdScrollController.addListener(() {
      double maxScroll = categoryAdScrollController.position.maxScrollExtent;
      double currentScroll = categoryAdScrollController.position.pixels;
      double delta = MediaQuery.of(context).size.width * 0.20;
      if (maxScroll - currentScroll <= delta) {
        if (widget.categoryName == Constants.other) {
          ref.read(otherAdsprovider.notifier).fetchMoreItems();
        } else {
          ref
              .read(showCatAdsProvider.notifier)
              .fetchMoreItems(widget.categoryName, widget.subCategoryName);
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    categoryAdScrollController.dispose();
    super.dispose();
  }

  String getDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDate = DateFormat('dd-MM-yy').format(dateTime);
    return formattedDate;
  }

  Widget progressIndicator() {
    if (Platform.isAndroid) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
      );
    } else if (Platform.isIOS) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }
    return const SizedBox();
  }

  Widget netIssue() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Platform.isAndroid
                ? Icons.wifi_off
                : Platform.isIOS
                    ? CupertinoIcons.wifi_slash
                    : null,
            color: Platform.isAndroid
                ? Colors.blue
                : Platform.isIOS
                    ? CupertinoColors.activeBlue
                    : null,
            size: 40,
          ),
          Text(
            'No Internet Connection',
            style: GoogleFonts.lato(),
          ),
          TextButton(
            child: Text(
              'Retry',
              style: GoogleFonts.lato(
                color: Platform.isAndroid
                    ? Colors.blue
                    : Platform.isIOS
                        ? CupertinoColors.activeBlue
                        : null,
              ),
            ),
            onPressed: () async {
              final x = ref.refresh(connectivityProvider);
              final y = ref.refresh(internetCheckerProvider);
              debugPrint(x.toString());
              debugPrint(y.toString());
              await ref.read(showCatAdsProvider.notifier).refreshItems(
                    widget.categoryName,
                    widget.subCategoryName,
                  );
            },
          )
        ],
      ),
    );
  }

  Center spinner() {
    if (Platform.isAndroid) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.blue,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Loading...',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      );
    } else if (Platform.isIOS) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(
              radius: 15,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Loading...',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      );
    }
    return const Center();
  }

  SliverFillRemaining noAds() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/emoji.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'No Ads Found',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> noCatAdSliver() {
    if (Platform.isAndroid) {
      return [noAds()];
    } else if (Platform.isIOS) {
      return [refreshIos(), noAds()];
    }
    return [];
  }

  List<Widget> noOtherAdSliver() {
    if (Platform.isAndroid) {
      return [noAds()];
    } else if (Platform.isIOS) {
      return [refreshOtherIos(), noAds()];
    }
    return [];
  }

  SliverToBoxAdapter fetchMoreAdsLoader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Platform.isAndroid
                  ? const CircularProgressIndicator(
                      color: Colors.blue,
                    )
                  : Platform.isIOS
                      ? const CupertinoActivityIndicator(
                          radius: 15,
                        )
                      : const SizedBox(),
              const SizedBox(height: 10),
              Text(
                'Fetching Content...',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> havingCatAdSliver(CategoryAdsState catAdState) {
    if (Platform.isAndroid) {
      return [
        catData(catAdState),
        if (catAdState.isLoadingMore) fetchMoreAdsLoader()
      ];
    } else if (Platform.isIOS) {
      return [
        refreshIos(),
        catData(catAdState),
        if (catAdState.isLoadingMore) fetchMoreAdsLoader()
      ];
    }
    return [];
  }

  List<Widget> havingOtherAdSliver(OtherAdState otherAdState) {
    if (Platform.isAndroid) {
      return [
        otherData(otherAdState),
        if (otherAdState.isLoadingMore) fetchMoreAdsLoader()
      ];
    } else if (Platform.isIOS) {
      return [
        refreshOtherIos(),
        otherData(otherAdState),
        if (otherAdState.isLoadingMore) fetchMoreAdsLoader()
      ];
    }
    return [];
  }

  Widget dataDisplay(Item ad) {
    return GestureDetector(
      onTap: () {
        if (Platform.isAndroid) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) {
                return ProductDetailScreenAI(
                  documentReference: ad.documentReference,
                );
              },
            ),
          );
        } else if (Platform.isIOS) {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (ctx) {
                return ProductDetailScreenAI(
                  documentReference: ad.documentReference,
                );
              },
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          border: Border.all(
            color: const Color.fromARGB(255, 200, 179, 172),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: ad.images[0],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return Center(
                    child: Platform.isAndroid
                        ? const Icon(
                            Icons.photo,
                            color: Colors.black,
                          )
                        : Platform.isIOS
                            ? const Icon(
                                CupertinoIcons.photo,
                                color: CupertinoColors.black,
                              )
                            : const SizedBox(),
                  );
                },
                errorWidget: (context, url, error) {
                  return Center(
                    child: Icon(
                      Platform.isAndroid
                          ? Icons.photo
                          : Platform.isIOS
                              ? CupertinoIcons.photo
                              : null,
                      size: 30,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹ ${ad.price}',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.adTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Platform.isAndroid
                            ? Icons.person
                            : Platform.isIOS
                                ? CupertinoIcons.person
                                : null,
                        size: 16,
                        color: Colors.brown[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ad.postedBy,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          color: Colors.brown[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding catData(CategoryAdsState data) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          childCount: data.items.length,
          (context, index) {
            final catAd = data.items[index];
            return dataDisplay(catAd);
          },
        ),
      ),
    );
  }

  SliverPadding otherData(OtherAdState data) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          childCount: data.items.length,
          (context, index) {
            final otherAd = data.items[index];
            return dataDisplay(otherAd);
          },
        ),
      ),
    );
  }

  CustomScrollView scrollView(CategoryAdsState catAdState) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: categoryAdScrollController,
      slivers: catAdState.items.isEmpty
          ? noCatAdSliver()
          : havingCatAdSliver(catAdState),
    );
  }

  CustomScrollView otherScrollView(OtherAdState otherAdState) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: categoryAdScrollController,
      slivers: otherAdState.items.isEmpty
          ? noOtherAdSliver()
          : havingOtherAdSliver(otherAdState),
    );
  }

  CupertinoSliverRefreshControl refreshIos() {
    return CupertinoSliverRefreshControl(
      onRefresh: () async {
        await ref.read(showCatAdsProvider.notifier).refreshItems(
              widget.categoryName,
              widget.subCategoryName,
            );
      },
    );
  }

  CupertinoSliverRefreshControl refreshOtherIos() {
    return CupertinoSliverRefreshControl(
      onRefresh: () async {
        await ref.read(otherAdsprovider.notifier).refreshItems();
      },
    );
  }

  Widget android() {
    final connectivityState = ref.watch(connectivityProvider);
    final internetState = ref.watch(internetCheckerProvider);
    return connectivityState.when(
      data: (connectivityResult) {
        if (connectivityResult == ConnectivityResult.none) {
          return netIssue();
        } else {
          return internetState.when(
            data: (hasInternet) {
              if (!hasInternet) {
                return netIssue();
              } else {
                if (widget.categoryName == Constants.other) {
                  final otherItemState = ref.watch(otherAdsprovider);
                  return otherItemState.when(
                    data: (otherAdState) {
                      return RefreshIndicator(
                        color: Colors.blue,
                        onRefresh: () async {
                          await ref
                              .read(otherAdsprovider.notifier)
                              .refreshItems();
                        },
                        child: otherScrollView(otherAdState),
                      );
                    },
                    error: (error, _) => retry(),
                    loading: spinner,
                  );
                } else {
                  final catItemState = ref.watch(showCatAdsProvider);
                  return catItemState.when(
                    data: (catAdState) {
                      return RefreshIndicator(
                        color: Colors.blue,
                        onRefresh: () async {
                          await ref
                              .read(showCatAdsProvider.notifier)
                              .refreshItems(
                                widget.categoryName,
                                widget.subCategoryName,
                              );
                        },
                        child: scrollView(catAdState),
                      );
                    },
                    error: (error, _) => retry(),
                    loading: spinner,
                  );
                }
              }
            },
            error: (error, _) => retry(),
            loading: progressIndicator,
          );
        }
      },
      error: (error, _) => retry(),
      loading: progressIndicator,
    );
  }

  Widget ios() {
    final connectivityState = ref.watch(connectivityProvider);
    final internetState = ref.watch(internetCheckerProvider);
    return connectivityState.when(
      data: (connectivityResult) {
        if (connectivityResult == ConnectivityResult.none) {
          return netIssue();
        } else {
          return internetState.when(
            data: (hasInternet) {
              if (!hasInternet) {
                return netIssue();
              } else {
                if (widget.categoryName == Constants.other) {
                  final otherItemState = ref.watch(otherAdsprovider);
                  return otherItemState.when(
                    data: (otherAdState) {
                      return otherScrollView(otherAdState);
                    },
                    error: (error, _) => retry(),
                    loading: spinner,
                  );
                } else {
                  final catItemState = ref.watch(showCatAdsProvider);
                  return catItemState.when(
                    data: (catAdState) {
                      return scrollView(catAdState);
                    },
                    error: (error, _) => retry(),
                    loading: spinner,
                  );
                }
              }
            },
            error: (error, _) => retry(),
            loading: progressIndicator,
          );
        }
      },
      error: (error, _) => retry(),
      loading: progressIndicator,
    );
  }

  Widget retry() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Something went wrong',
            style: GoogleFonts.lato(color: Colors.black),
          ),
          const SizedBox(height: 10),
          Platform.isAndroid
              ? TextButton(
                  onPressed: () async {
                    final x = ref.refresh(connectivityProvider);
                    final y = ref.refresh(internetCheckerProvider);
                    debugPrint(x.toString());
                    debugPrint(y.toString());
                    await ref.read(showCatAdsProvider.notifier).refreshItems(
                          widget.categoryName,
                          widget.subCategoryName,
                        );
                  },
                  child: Text(
                    'Retry',
                    style: GoogleFonts.lato(color: Colors.blue),
                  ),
                )
              : CupertinoButton(
                  child: Text(
                    'Retry',
                    style: GoogleFonts.lato(color: CupertinoColors.activeBlue),
                  ),
                  onPressed: () async {
                    final x = ref.refresh(connectivityProvider);
                    final y = ref.refresh(internetCheckerProvider);
                    debugPrint(x.toString());
                    debugPrint(y.toString());
                    await ref.read(showCatAdsProvider.notifier).refreshItems(
                          widget.categoryName,
                          widget.subCategoryName,
                        );
                  },
                )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ref.read(showCatAdsProvider.notifier).resetState();
      },
      child: Platform.isAndroid
          ? android()
          : Platform.isIOS
              ? ios()
              : const SizedBox(),
    );
  }
}
