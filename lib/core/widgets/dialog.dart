import 'dart:ui' show ImageFilter, SemanticsRole, clampDouble, lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const EdgeInsets _defaultInsetPadding = EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0);

/// A Material Design inspired dialog for the project.
///
/// This dialog widget is a clone of the Flutter Material [Dialog] widget,
/// but it is customized to follow the project's design system.
class AppDialog extends StatelessWidget {
  /// Creates a dialog.
  ///
  /// Typically used in conjunction with [showAppDialog].
  const AppDialog({
    super.key,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
    this.insetPadding,
    this.clipBehavior,
    this.shape,
    this.alignment,
    this.child,
    this.semanticsRole = SemanticsRole.dialog,
    this.constraints,
  }) : assert(elevation == null || elevation >= 0.0),
       _fullscreen = false;

  /// Creates a fullscreen dialog.
  ///
  /// Typically used in conjunction with [showAppDialog].
  const AppDialog.fullscreen({
    super.key,
    this.backgroundColor,
    this.insetAnimationDuration = Duration.zero,
    this.insetAnimationCurve = Curves.decelerate,
    this.child,
    this.semanticsRole = SemanticsRole.dialog,
  }) : elevation = 0,
       shadowColor = null,
       surfaceTintColor = null,
       insetPadding = EdgeInsets.zero,
       clipBehavior = Clip.none,
       shape = null,
       alignment = null,
       constraints = null,
       _fullscreen = true;

  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Duration insetAnimationDuration;
  final Curve insetAnimationCurve;
  final EdgeInsets? insetPadding;
  final Clip? clipBehavior;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  final Widget? child;
  final bool _fullscreen;
  final SemanticsRole semanticsRole;
  final BoxConstraints? constraints;

  static const Color defaultBackgroundColor = AppColors.neutral10;
  static const double defaultElevation = 6.0;
  static const ShapeBorder defaultShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12.0)),
  );

  @override
  Widget build(BuildContext context) {
    final DialogThemeData dialogTheme = DialogTheme.of(context);
    final EdgeInsets effectivePadding =
        MediaQuery.viewInsetsOf(context) +
        (insetPadding ?? dialogTheme.insetPadding ?? _defaultInsetPadding);

    final BoxConstraints boxConstraints =
        constraints ?? dialogTheme.constraints ?? const BoxConstraints(minWidth: 280.0);

    Widget dialogChild;

    if (_fullscreen) {
      dialogChild = Material(
        color: backgroundColor ?? dialogTheme.backgroundColor ?? defaultBackgroundColor,
        child: child,
      );
    } else {
      dialogChild = Align(
        alignment: alignment ?? dialogTheme.alignment ?? Alignment.center,
        child: ConstrainedBox(
          constraints: boxConstraints,
          child: Material(
            color: backgroundColor ?? dialogTheme.backgroundColor ?? defaultBackgroundColor,
            elevation: elevation ?? dialogTheme.elevation ?? defaultElevation,
            shadowColor: shadowColor ?? dialogTheme.shadowColor ?? Colors.black12,
            surfaceTintColor:
                surfaceTintColor ?? dialogTheme.surfaceTintColor ?? Colors.transparent,
            shape: shape ?? dialogTheme.shape ?? defaultShape,
            type: MaterialType.card,
            clipBehavior: clipBehavior ?? dialogTheme.clipBehavior ?? Clip.none,
            child: child,
          ),
        ),
      );
    }

    return Semantics(
      role: semanticsRole,
      child: AnimatedPadding(
        padding: effectivePadding,
        duration: insetAnimationDuration,
        curve: insetAnimationCurve,
        child: MediaQuery.removeViewInsets(
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          context: context,
          child: dialogChild,
        ),
      ),
    );
  }
}

/// A Material Design inspired alert dialog for the project.
///
/// An alert dialog informs the user about situations that require acknowledgment.
class AppAlertDialog extends StatelessWidget {
  /// Creates an alert dialog.
  ///
  /// Typically used in conjunction with [showAppDialog].
  const AppAlertDialog({
    super.key,
    this.icon,
    this.iconPadding,
    this.iconColor,
    this.title,
    this.titlePadding,
    this.titleTextStyle,
    this.content,
    this.contentPadding,
    this.contentTextStyle,
    this.actions,
    this.actionsPadding,
    this.actionsAlignment,
    this.actionsOverflowAlignment,
    this.actionsOverflowDirection,
    this.actionsOverflowButtonSpacing,
    this.buttonPadding,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.semanticLabel,
    this.insetPadding,
    this.clipBehavior,
    this.shape,
    this.alignment,
    this.constraints,
    this.scrollable = false,
    this.iconBgColor,
    this.showIconBackground = true,
    this.iconShape = BoxShape.circle,
    this.showCloseButton = false,
    this.onClose,
  });

  final Widget? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool showIconBackground;
  final BoxShape iconShape;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry? iconPadding;
  final Widget? title;
  final EdgeInsetsGeometry? titlePadding;
  final TextStyle? titleTextStyle;
  final Widget? content;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? contentTextStyle;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final OverflowBarAlignment? actionsOverflowAlignment;
  final VerticalDirection? actionsOverflowDirection;
  final double? actionsOverflowButtonSpacing;
  final EdgeInsetsGeometry? buttonPadding;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final String? semanticLabel;
  final EdgeInsets? insetPadding;
  final Clip? clipBehavior;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final bool scrollable;

  static TextStyle _defaultTitleStyle(BuildContext context) => 
      AppTextStyles.titleLarge.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.neutral900,
      );

  static TextStyle _defaultContentStyle(BuildContext context) => 
      AppTextStyles.bodyMedium.copyWith(
        color: AppColors.neutral600,
      );

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final ThemeData theme = Theme.of(context);
    final DialogThemeData dialogTheme = DialogTheme.of(context);

    String? label = semanticLabel;
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        label ??= MaterialLocalizations.of(context).alertDialogLabel;
    }

    const double fontSizeToScale = 14.0;
    final double effectiveTextScale =
        MediaQuery.textScalerOf(context).scale(fontSizeToScale) / fontSizeToScale;
    final double paddingScaleFactor = _scalePadding(effectiveTextScale);
    final TextDirection? textDirection = Directionality.maybeOf(context);

    Widget? iconWidget;
    Widget? titleWidget;
    Widget? contentWidget;
    Widget? actionsWidget;

    if (icon != null) {
      final bool belowIsTitle = title != null;
      final bool belowIsContent = !belowIsTitle && content != null;
      final EdgeInsets defaultIconPadding = EdgeInsets.only(
        left: 24.0,
        top: 24.0,
        right: 24.0,
        bottom: belowIsTitle
            ? 16.0
            : belowIsContent
            ? 0.0
            : 24.0,
      );
      final EdgeInsets effectiveIconPadding =
          iconPadding?.resolve(textDirection) ?? defaultIconPadding;
      iconWidget = Padding(
        padding: EdgeInsets.only(
          left: effectiveIconPadding.left * paddingScaleFactor,
          right: effectiveIconPadding.right * paddingScaleFactor,
          top: effectiveIconPadding.top * paddingScaleFactor,
          bottom: effectiveIconPadding.bottom,
        ),
        child: Align(
          alignment: Alignment.center,
          child: showIconBackground 
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor ?? AppColors.primary400.withValues(alpha: 0.15),
                  shape: iconShape,
                  borderRadius: iconShape == BoxShape.circle ? null : BorderRadius.circular(12),
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: iconColor ?? dialogTheme.iconColor ?? AppColors.secondary500,
                  ),
                  child: icon!,
                ),
              )
            : IconTheme(
                data: IconThemeData(
                  color: iconColor ?? dialogTheme.iconColor ?? AppColors.secondary500,
                ),
                child: icon!,
              ),
        ),
      );
    }

    if (title != null) {
      final EdgeInsets defaultTitlePadding = EdgeInsets.only(
        left: 24.0,
        top: icon == null ? 24.0 : 0.0,
        right: 24.0,
        bottom: content == null ? 20.0 : 0.0,
      );
      final EdgeInsets effectiveTitlePadding =
          titlePadding?.resolve(textDirection) ?? defaultTitlePadding;
      titleWidget = Padding(
        padding: EdgeInsets.only(
          left: effectiveTitlePadding.left * paddingScaleFactor,
          right: effectiveTitlePadding.right * paddingScaleFactor,
          top: icon == null
              ? effectiveTitlePadding.top * paddingScaleFactor
              : effectiveTitlePadding.top,
          bottom: effectiveTitlePadding.bottom,
        ),
        child: DefaultTextStyle(
          style: titleTextStyle ?? dialogTheme.titleTextStyle ?? _defaultTitleStyle(context),
          textAlign: icon == null ? TextAlign.start : TextAlign.center,
          child: Semantics(
            namesRoute: label == null && theme.platform != TargetPlatform.iOS,
            container: true,
            child: title,
          ),
        ),
      );
    }

    if (content != null) {
      final EdgeInsets defaultContentPadding = const EdgeInsets.only(
        left: 24.0,
        top: 16.0,
        right: 24.0,
        bottom: 16.0,
      );
      final EdgeInsets effectiveContentPadding =
          contentPadding?.resolve(textDirection) ?? defaultContentPadding;
      contentWidget = Padding(
        padding: EdgeInsets.only(
          left: effectiveContentPadding.left * paddingScaleFactor,
          right: effectiveContentPadding.right * paddingScaleFactor,
          top: title == null && icon == null
              ? effectiveContentPadding.top * paddingScaleFactor
              : effectiveContentPadding.top,
          bottom: effectiveContentPadding.bottom,
        ),
        child: DefaultTextStyle(
          style: contentTextStyle ?? dialogTheme.contentTextStyle ?? _defaultContentStyle(context),
          child: Semantics(container: true, explicitChildNodes: true, child: content),
        ),
      );
    }

    if (actions != null) {
      final double spacing = (buttonPadding?.horizontal ?? 16) / 2;
      actionsWidget = Padding(
        padding:
            actionsPadding ??
            dialogTheme.actionsPadding ??
            const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 12.0),
        child: OverflowBar(
          alignment: actionsAlignment ?? MainAxisAlignment.end,
          spacing: spacing,
          overflowAlignment: actionsOverflowAlignment ?? OverflowBarAlignment.end,
          overflowDirection: actionsOverflowDirection ?? VerticalDirection.down,
          overflowSpacing: actionsOverflowButtonSpacing ?? 0,
          children: actions!,
        ),
      );
    }

    List<Widget> columnChildren;
    if (scrollable) {
      columnChildren = <Widget>[
        if (title != null || content != null)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ?iconWidget,
                  ?titleWidget,
                  ?contentWidget,
                ],
              ),
            ),
          ),
        ?actionsWidget,
      ];
    } else {
      columnChildren = <Widget>[
        ?iconWidget,
        ?titleWidget,
        if (contentWidget != null) Flexible(child: contentWidget),
        ?actionsWidget,
      ];
    }

    Widget dialogChild = IntrinsicWidth(
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columnChildren,
          ),
          if (showCloseButton)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: onClose ?? () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.neutral500,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );

    if (label != null) {
      dialogChild = Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: label,
        child: dialogChild,
      );
    }

    return AppDialog(
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      shape: shape,
      alignment: alignment,
      constraints: constraints,
      semanticsRole: SemanticsRole.alertDialog,
      child: dialogChild,
    );
  }
}

/// Displays a project-styled dialog above the current contents of the app.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool fullscreenDialog = false,
  bool? requestFocus,
  AnimationStyle? animationStyle,
  double barrierBlur = 0.0,
}) {
  assert(debugCheckHasMaterialLocalizations(context));

  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: useRootNavigator).context,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    AppDialogRoute<T>(
      context: context,
      builder: builder,
      barrierColor:
          barrierColor ??
          DialogTheme.of(context).barrierColor ??
          Theme.of(context).dialogTheme.barrierColor ??
          Colors.black54,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierBlur: barrierBlur,
      useSafeArea: useSafeArea,
      settings: routeSettings,
      themes: themes,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior: traversalEdgeBehavior ?? TraversalEdgeBehavior.closedLoop,
      requestFocus: requestFocus,
      animationStyle: animationStyle,
      fullscreenDialog: fullscreenDialog,
    ),
  );
}

/// A dialog route with project animations.
class AppDialogRoute<T> extends RawDialogRoute<T> {
  AppDialogRoute({
    required BuildContext context,
    required WidgetBuilder builder,
    CapturedThemes? themes,
    super.barrierColor = Colors.black54,
    super.barrierDismissible,
    String? barrierLabel,
    bool useSafeArea = true,
    super.settings,
    super.requestFocus,
    super.anchorPoint,
    super.traversalEdgeBehavior,
    super.fullscreenDialog,
    this.barrierBlur = 0.0,
    AnimationStyle? animationStyle,
  }) : _animationStyle = animationStyle,
       super(
         pageBuilder:
             (
               BuildContext buildContext,
               Animation<double> animation,
               Animation<double> secondaryAnimation,
             ) {
               final Widget pageChild = Builder(builder: builder);
               Widget dialog = themes?.wrap(pageChild) ?? pageChild;
               if (useSafeArea) {
                 dialog = SafeArea(child: dialog);
               }

               if (barrierBlur > 0) {
                 return Stack(
                   children: [
                     Positioned.fill(
                       child: BackdropFilter(
                         filter: ImageFilter.blur(sigmaX: barrierBlur, sigmaY: barrierBlur),
                         child: const SizedBox.expand(),
                       ),
                     ),
                     dialog,
                   ],
                 );
               }

               return dialog;
             },
         barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
         transitionDuration: animationStyle?.duration ?? const Duration(milliseconds: 200),
         transitionBuilder: _buildAppDialogTransitions,
       );

  CurvedAnimation? _curvedAnimation;
  final AnimationStyle? _animationStyle;

  void _setAnimation(Animation<double> animation) {
    if (_curvedAnimation?.parent != animation) {
      _curvedAnimation?.dispose();
      _curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: _animationStyle?.curve ?? Curves.easeOutCubic,
        reverseCurve: _animationStyle?.reverseCurve ?? Curves.easeInCubic,
      );
    }
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    _setAnimation(animation);
    return FadeTransition(
      opacity: _curvedAnimation!,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(_curvedAnimation!),
        child: super.buildTransitions(context, animation, secondaryAnimation, child),
      ),
    );
  }

  @override
  void dispose() {
    _curvedAnimation?.dispose();
    super.dispose();
  }

  final double barrierBlur;
}

Widget _buildAppDialogTransitions(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  // The transition is handled within AppDialogRoute
  return child;
}

double _scalePadding(double textScaleFactor) {
  final double clampedTextScaleFactor = clampDouble(textScaleFactor, 1.0, 2.0);
  return lerpDouble(1.0, 1.0 / 3.0, clampedTextScaleFactor - 1.0)!;
}
