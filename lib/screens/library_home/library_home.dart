import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../screens/library_home/band_screen_library_home_list.dart';
import '../../screens/library_home/small_screen_library_home_list.dart';
import '../../widgets/belt_container.dart';
import '../../widgets/start_screen/providers/start_screen_layout_manager.dart';
import '../../widgets/navigation_bar/page_content_frame.dart';
import '../../providers/library_path.dart';
import '../../providers/responsive_providers.dart';

import 'large_screen_library_home_list.dart';

class LibraryHomePage extends StatefulWidget {
  const LibraryHomePage({super.key});

  @override
  State<LibraryHomePage> createState() => _LibraryHomePageState();
}

class _LibraryHomePageState extends State<LibraryHomePage> {
  final _layoutManager = StartScreenLayoutManager();

  @override
  void dispose() {
    super.dispose();
    _layoutManager.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryPath = Provider.of<LibraryPathProvider>(context).currentPath;

    if (libraryPath == null) {
      return Container();
    }

    return ChangeNotifierProvider<StartScreenLayoutManager>.value(
      value: _layoutManager,
      child: SmallerOrEqualTo(
        deviceType: DeviceType.dock,
        builder: (context, isDock) {
          return PageContentFrame(
            top: !isDock,
            child: DeviceTypeBuilder(
              deviceType: const [
                DeviceType.band,
                DeviceType.belt,
                DeviceType.dock,
                DeviceType.zune,
                DeviceType.tv
              ],
              builder: (context, activeBreakpoint) {
                if (activeBreakpoint == DeviceType.belt) {
                  return BeltContainer(
                    child: BandScreenLibraryHomeListView(
                      layoutManager: _layoutManager,
                    ),
                  );
                }

                if (activeBreakpoint == DeviceType.dock ||
                    activeBreakpoint == DeviceType.band) {
                  return BandScreenLibraryHomeListView(
                    layoutManager: _layoutManager,
                  );
                }

                if (activeBreakpoint == DeviceType.zune) {
                  return SmallScreenLibraryHomeListView(
                    layoutManager: _layoutManager,
                  );
                }

                return LargeScreenLibraryHomeListView(
                  libraryPath: libraryPath,
                  layoutManager: _layoutManager,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
