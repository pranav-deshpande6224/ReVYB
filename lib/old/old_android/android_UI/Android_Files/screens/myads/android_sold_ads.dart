import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resell/Authentication/Providers/internet_provider.dart';
import 'package:resell/Authentication/android_ios/handlers/auth_handler.dart';
import 'package:resell/UIPart/android_ios/widgets/ad_card.dart';
import 'package:resell/UIPart/android_ios/Providers/pagination_active_ads/show_sold_ads.dart';

class AndroidSoldAds extends ConsumerStatefulWidget {
  const AndroidSoldAds({super.key});

  @override
  ConsumerState<AndroidSoldAds> createState() => _AndroidSoldadsState();
}

class _AndroidSoldadsState extends ConsumerState<AndroidSoldAds> {
  late AuthHandler handler;
  final ScrollController soldAdScrollControllerAndroid = ScrollController();

  @override
  void initState() {
    handler = AuthHandler.authHandlerInstance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showSoldAdsProvider.notifier).fetchInitialItems();
    });
    soldAdScrollControllerAndroid.addListener(
      () {
        double maxScroll =
            soldAdScrollControllerAndroid.position.maxScrollExtent;
        double currentScroll = soldAdScrollControllerAndroid.position.pixels;
        double delta = MediaQuery.of(context).size.width * 0.20;
        if (maxScroll - currentScroll <= delta) {
          ref.read(showSoldAdsProvider.notifier).fetchMoreItems();
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    soldAdScrollControllerAndroid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityProvider);
    final internetState = ref.watch(internetCheckerProvider);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ref.read(showSoldAdsProvider.notifier).resetState();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 10,
          title: Text(
            'My Sold Ads',
            style: GoogleFonts.lato(),
          ),
        ),
        body: SafeArea(
          child: connectivityState.when(
            data: (connectivityResult) {
              if (connectivityResult == ConnectivityResult.none) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: Colors.blue,
                        size: 40,
                      ),
                      Text(
                        'No Internet Connection',
                        style: GoogleFonts.lato(),
                      ),
                      TextButton(
                        child: Text(
                          'Retry',
                          style: GoogleFonts.lato(color: Colors.blue),
                        ),
                        onPressed: () async {
                          final x = ref.refresh(connectivityProvider);
                          final y = ref.refresh(internetCheckerProvider);
                          debugPrint(x.toString());
                          debugPrint(y.toString());
                          await ref
                              .read(showSoldAdsProvider.notifier)
                              .refreshItems();
                        },
                      )
                    ],
                  ),
                );
              } else {
                return internetState.when(
                  data: (hasInternet) {
                    if (!hasInternet) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              color: Colors.blue,
                              size: 40,
                            ),
                            Text(
                              'No Internet Connection',
                              style: GoogleFonts.lato(),
                            ),
                            TextButton(
                              child: Text(
                                'Retry',
                                style: GoogleFonts.lato(color: Colors.blue),
                              ),
                              onPressed: () async {
                                final x = ref.refresh(connectivityProvider);
                                final y = ref.refresh(internetCheckerProvider);
                                debugPrint(x.toString());
                                debugPrint(y.toString());
                                await ref
                                    .read(showSoldAdsProvider.notifier)
                                    .refreshItems();
                              },
                            )
                          ],
                        ),
                      );
                    } else {
                      final soldItemState = ref.watch(showSoldAdsProvider);
                      return soldItemState.when(
                        data: (soldAdState) {
                          return RefreshIndicator(
                            color: Colors.blue,
                            child: CustomScrollView(
                              controller: soldAdScrollControllerAndroid,
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                soldAdState.items.isEmpty
                                    ? SliverFillRemaining(
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'assets/images/emoji.png',
                                                height: 80,
                                                width: 80,
                                              ),
                                              Text(
                                                'No Sold Ads',
                                                style: GoogleFonts.lato(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (ctx, index) {
                                            final item =
                                                soldAdState.items[index];
                                            return AdCard(
                                              cardIndex: index,
                                              ad: item,
                                              adSold: null,
                                              isSold: true,
                                            );
                                          },
                                          childCount: soldAdState.items.length,
                                        ),
                                      ),
                                if (soldAdState.isLoadingMore)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
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
                                              'Fetching Content...',
                                              style: GoogleFonts.lato(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onRefresh: () async {
                              await ref
                                  .read(showSoldAdsProvider.notifier)
                                  .refreshItems();
                            },
                          );
                        },
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                        loading: () {
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
                        },
                      );
                    }
                  },
                  error: (error, _) => Center(
                    child: Text('Error: $error'),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  ),
                );
              }
            },
            error: (error, _) => Center(child: Text('Error: $error')),
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
