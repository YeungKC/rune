import '../../utils/settings_manager.dart';
import '../../utils/file_storage/mac_secure_manager.dart';

final SettingsManager settingsManager = SettingsManager();

class FileStorageService {
  static const String _openedFilesKey = 'library_path';

  // Get the list of opened files
  Future<List<String>> _getOpenedFiles() async {
    return List<String>.from(
      await settingsManager.getValue<List<dynamic>>(_openedFilesKey) ?? [],
    );
  }

  // Store file path
  void storeFilePath(String filePath) async {
    List<String> openedFiles = await _getOpenedFiles();

    // If the file path already exists, remove it to re-add it to the end of the list
    openedFiles.remove(filePath);
    openedFiles.add(filePath);

    await MacSecureManager.shared.saveBookmark(filePath);

    // Store the updated list of file paths
    settingsManager.setValue(_openedFilesKey, openedFiles);
  }

  // Get the last opened file
  Future<String?> getLastOpenedFile() async {
    List<String> openedFiles = await _getOpenedFiles();
    if (openedFiles.isNotEmpty) {
      return openedFiles.last;
    }
    return null;
  }

  // Get all opened files
  Future<List<String>> getAllOpenedFiles() {
    return _getOpenedFiles();
  }

  // Clear all opened files
  Future<void> clearAllOpenedFiles() async {
    await settingsManager.removeValue(_openedFilesKey);
  }

  // Remove a specific file path
  Future<void> removeFilePath(String filePath) async {
    List<String> openedFiles = await _getOpenedFiles();
    openedFiles.remove(filePath);
    await settingsManager.setValue(_openedFilesKey, openedFiles);
  }
}
