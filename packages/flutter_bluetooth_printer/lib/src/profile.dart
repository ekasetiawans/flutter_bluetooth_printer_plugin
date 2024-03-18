part of flutter_bluetooth_printer;

List<Map> printProfiles = [];
Map printCapabilities = {};

class CodePage {
  CodePage(this.id, this.name);
  int id;
  String name;
}

class CapabilityProfile {
  CapabilityProfile._internal(this.name, this.codePages);

  /// [ensureProfileLoaded]
  /// this method will cache the profile json into data which will
  /// speed up the next loop and searching profile
  static void ensureProfileLoaded({String? path}) {
    /// check where this global capabilities is empty then load capabilities.json
    /// else do nothing
    if (printCapabilities.isEmpty == true) {
      printCapabilities = capabilities;

      (capabilities['profiles'] as Map).forEach((k, v) {
        printProfiles.add({
          'key': k,
          'vendor': v['vendor'] is String ? v['vendor'] : '',
          'name': v['name'] is String ? v['name'] : '',
          'description': v['description'] is String ? v['description'] : '',
        });
      });

      /// assert that the capabilities will be not empty
      assert(printCapabilities.isNotEmpty);
    } else {
      debugPrint("capabilities.length is already loaded");
    }
  }

  /// Public factory
  static CapabilityProfile load({String name = 'default'}) {
    ///
    ensureProfileLoaded();

    var profile = printCapabilities['profiles'][name];

    if (profile == null) {
      throw Exception("The CapabilityProfile '$name' does not exist");
    }

    List<CodePage> list = [];
    (profile['codePages'] as Map).forEach((k, v) {
      list.add(CodePage(int.parse(k), v));
    });

    // Call the private constructor
    return CapabilityProfile._internal(name, list);
  }

  String name;
  List<CodePage> codePages;

  int getCodePageId(String? codePage) {
    if (codePages.isEmpty) {
      throw Exception("The CapabilityProfile isn't initialized");
    }

    return codePages
        .firstWhere((cp) => cp.name == codePage,
            // ignore: unnecessary_cast
            orElse: (() => throw Exception(
                    "Code Page '$codePage' isn't defined for this profile"))
                as CodePage Function()?)
        .id;
  }

  static List<dynamic> getAvailableProfiles() {
    /// ensure the capabilities is not empty
    ensureProfileLoaded();

    var profiles = printCapabilities['profiles'] as Map;

    List<dynamic> res = [];

    profiles.forEach((k, v) {
      res.add({
        'key': k,
        'vendor': v['vendor'] is String ? v['vendor'] : '',
        'name': v['name'] is String ? v['name'] : '',
        'description': v['description'] is String ? v['description'] : '',
      });
    });

    return res;
  }
}
