import 'package:flutter/material.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final isDesktop = constraints.maxWidth >= 1024;

        return Scaffold(
          appBar: appBar,
          body: SafeArea(
            child: isDesktop
                ? _buildDesktopLayout(context, body ?? const SizedBox())
                : isTablet
                    ? _buildTabletLayout(context, body ?? const SizedBox())
                    : _buildMobileLayout(context, body ?? const SizedBox()),
          ),
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMarginMobile),
      child: child,
    );
  }

  Widget _buildTabletLayout(BuildContext context, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMarginTablet),
      child: child,
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMarginDesktop),
          child: child,
        ),
      ),
    );
  }
}

class TwoPaneLayout extends StatelessWidget {
  final Widget leftPane;
  final Widget rightPane;
  final double leftPaneWidthRatio;
  final double breakpoint;

  const TwoPaneLayout({
    super.key,
    required this.leftPane,
    required this.rightPane,
    this.leftPaneWidthRatio = 0.6,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: (leftPaneWidthRatio * 100).round(),
                child: leftPane,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: ((1 - leftPaneWidthRatio) * 100).round(),
                child: rightPane,
              ),
            ],
          );
        } else {
          return Column(
            children: [
              leftPane,
              const SizedBox(height: AppSpacing.lg),
              rightPane,
            ],
          );
        }
      },
    );
  }
}