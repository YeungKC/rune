import 'package:fluent_ui/fluent_ui.dart';

class NavigationItem {
  final String title;
  final String path;
  final bool hidden;
  final bool tappable;
  final bool zuneOnly;
  final List<NavigationItem>? children;
  final List<SingleActivator>? shortcuts;

  NavigationItem(
    this.title,
    this.path, {
    this.hidden = false,
    this.tappable = true,
    this.children = const [],
    this.zuneOnly = false,
    this.shortcuts,
  });

  @override
  String toString() {
    return 'NavigationItem(title: $title, path: $path, hidden: $hidden)';
  }
}
