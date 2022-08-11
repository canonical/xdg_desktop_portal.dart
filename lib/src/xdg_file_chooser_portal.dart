import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// A pattern used to match files.
abstract class XdgFileChooserFilterPattern {
  int get _id;
  String get _pattern;

  XdgFileChooserFilterPattern();
}

/// A pattern used to match files using a glob string.
class XdgFileChooserGlobPattern extends XdgFileChooserFilterPattern {
  /// A glob patterns, e.g. '*.png'
  final String pattern;

  @override
  int get _id => 0;

  @override
  String get _pattern => pattern;

  XdgFileChooserGlobPattern(this.pattern);

  @override
  int get hashCode => pattern.hashCode;

  @override
  bool operator ==(other) =>
      other is XdgFileChooserGlobPattern && other.pattern == pattern;

  @override
  String toString() => '$runtimeType($pattern)';
}

/// A pattern used to match files using a MIME type.
class XdgFileChooserMimeTypePattern extends XdgFileChooserFilterPattern {
  /// A MIME type, e.g. 'image/png'
  final String mimeType;

  @override
  int get _id => 1;

  @override
  String get _pattern => mimeType;

  XdgFileChooserMimeTypePattern(this.mimeType);

  @override
  int get hashCode => mimeType.hashCode;

  @override
  bool operator ==(other) =>
      other is XdgFileChooserMimeTypePattern && other.mimeType == mimeType;

  @override
  String toString() => '$runtimeType($mimeType)';
}

/// A file filter in use in a file chooser.
class XdgFileChooserFilter {
  /// The name of this filter.
  final String name;

  /// Patterns to match files against.
  final List<XdgFileChooserFilterPattern> patterns;

  XdgFileChooserFilter(
      this.name, Iterable<XdgFileChooserFilterPattern> patterns)
      : patterns = patterns.toList();

  @override
  int get hashCode => Object.hash(name, Object.hashAll(patterns));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is XdgFileChooserFilter &&
        other.name == name &&
        listEquals(other.patterns, patterns);
  }

  @override
  String toString() => '$runtimeType($name, $patterns)';
}

XdgFileChooserFilter? _decodeFilter(DBusValue? value) {
  if (value == null || value.signature != DBusSignature('(sa(us))')) {
    return null;
  }

  var nameAndPatterns = value.asStruct();
  var name = nameAndPatterns[0].asString();
  var patterns = nameAndPatterns[1]
      .asArray()
      .map((v) {
        var idAndPattern = v.asStruct();
        var id = idAndPattern[0].asUint32();
        var pattern = idAndPattern[1].asString();
        switch (id) {
          case 0:
            return XdgFileChooserGlobPattern(pattern);
          case 1:
            return XdgFileChooserMimeTypePattern(pattern);
          default:
            return null;
        }
      })
      .where((p) => p != null)
      .cast<XdgFileChooserFilterPattern>();

  return XdgFileChooserFilter(name, patterns);
}

DBusValue _encodeFilter(XdgFileChooserFilter filter) {
  return DBusStruct([
    DBusString(filter.name),
    DBusArray(
        DBusSignature('(us)'),
        filter.patterns.map((pattern) => DBusStruct(
            [DBusUint32(pattern._id), DBusString(pattern._pattern)])))
  ]);
}

DBusValue _encodeFilters(Iterable<XdgFileChooserFilter> filters) {
  return DBusArray(
      DBusSignature('(sa(us))'), filters.map((f) => _encodeFilter(f)));
}

/// A choice to give the user in a file chooser dialog.
/// Normally implemented as a combo box.
class XdgFileChooserChoice {
  /// Unique ID for this choice.
  final String id;

  /// User-visible label for this choice.
  final String label;

  /// User visible value labels keyed by ID.
  final Map<String, String> values;

  /// ID of the initiially selected value in [values].
  final String initialSelection;

  XdgFileChooserChoice(
      {required this.id,
      required this.label,
      this.values = const {},
      this.initialSelection = ''});

  DBusValue _encode() {
    return DBusStruct([
      DBusString(id),
      DBusString(label),
      DBusArray(
          DBusSignature('(ss)'),
          values.entries.map(
              (e) => DBusStruct([DBusString(e.key), DBusString(e.value)]))),
      DBusString(initialSelection)
    ]);
  }
}

DBusValue _encodeChoices(Iterable<XdgFileChooserChoice> choices) {
  return DBusArray(
      DBusSignature('(ssa(ss)s)'), choices.map((c) => c._encode()));
}

Map<String, String> _decodeChoicesResult(DBusValue? value) {
  if (value == null || value.signature != DBusSignature('a(ss)')) {
    return {};
  }

  var result = <String, String>{};
  for (var v in value.asArray()) {
    var ids = v.asStruct();
    var choiceId = ids[0].asString();
    var valueId = ids[1].asString();
    result[choiceId] = valueId;
  }

  return result;
}

/// Result of a request for access to files.
class XdgFileChooserPortalOpenFileResult {
  /// The URIs selected in the file chooser.
  final List<String> uris;

  /// Result of the choices taken in the chooser.
  final Map<String, String> choices;

  /// Selected filter that was used in the chooser.
  final XdgFileChooserFilter? currentFilter;

  XdgFileChooserPortalOpenFileResult(
      {required this.uris,
      this.choices = const {},
      required this.currentFilter});
}

/// Result of a request asking for a location to save a file.
class XdgFileChooserPortalSaveFileResult {
  /// The URIs selected in the file chooser.
  final List<String> uris;

  /// Result of the choices taken in the chooser.
  final Map<String, String> choices;

  /// Selected filter that was used in the chooser.
  final XdgFileChooserFilter? currentFilter;

  XdgFileChooserPortalSaveFileResult(
      {required this.uris,
      this.choices = const {},
      required this.currentFilter});
}

/// Result of a request asking for a folder as a location to save one or more files.
class XdgFileChooserPortalSaveFilesResult {
  /// The URIs selected in the file chooser.
  final List<String> uris;

  /// Result of the choices taken in the chooser.
  final Map<String, String> choices;

  XdgFileChooserPortalSaveFilesResult(
      {required this.uris, this.choices = const {}});
}

/// Portal to request access to files.
class XdgFileChooserPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgFileChooserPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.FileChooser', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Ask to open one or more files.
  Stream<XdgFileChooserPortalOpenFileResult> openFile(
      {required String title,
      String parentWindow = '',
      String? acceptLabel,
      bool? modal,
      bool? multiple,
      bool? directory,
      Iterable<XdgFileChooserFilter> filters = const [],
      XdgFileChooserFilter? currentFilter,
      Iterable<XdgFileChooserChoice> choices = const []}) {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      if (acceptLabel != null) {
        options['accept_label'] = DBusString(acceptLabel);
      }
      if (modal != null) {
        options['modal'] = DBusBoolean(modal);
      }
      if (multiple != null) {
        options['multiple'] = DBusBoolean(multiple);
      }
      if (directory != null) {
        options['directory'] = DBusBoolean(directory);
      }
      if (filters.isNotEmpty) {
        options['filters'] = _encodeFilters(filters);
      }
      if (currentFilter != null) {
        options['current_filter'] = _encodeFilter(currentFilter);
      }
      if (choices.isNotEmpty) {
        options['choices'] = _encodeChoices(choices);
      }
      var result = await _object.callMethod(
          'org.freedesktop.portal.FileChooser',
          'OpenFile',
          [
            DBusString(parentWindow),
            DBusString(title),
            DBusDict.stringVariant(options)
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    return request.stream.map((result) {
      var urisValue = result['uris'];
      var uris = urisValue?.signature == DBusSignature('as')
          ? urisValue!.asStringArray().toList()
          : <String>[];
      var choicesResult = _decodeChoicesResult(result['choices']);
      var selectedFilter = _decodeFilter(result['current_filter']);

      return XdgFileChooserPortalOpenFileResult(
          uris: uris, choices: choicesResult, currentFilter: selectedFilter);
    });
  }

  /// Ask for a location to save a file.
  Stream<XdgFileChooserPortalSaveFileResult> saveFile(
      {required String title,
      String parentWindow = '',
      String? acceptLabel,
      bool? modal,
      Iterable<XdgFileChooserFilter> filters = const [],
      XdgFileChooserFilter? currentFilter,
      Iterable<XdgFileChooserChoice> choices = const [],
      String? currentName,
      Uint8List? currentFolder,
      Uint8List? currentFile}) {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      if (acceptLabel != null) {
        options['accept_label'] = DBusString(acceptLabel);
      }
      if (modal != null) {
        options['modal'] = DBusBoolean(modal);
      }
      if (filters.isNotEmpty) {
        options['filters'] = _encodeFilters(filters);
      }
      if (currentFilter != null) {
        options['current_filter'] = _encodeFilter(currentFilter);
      }
      if (choices.isNotEmpty) {
        options['choices'] = _encodeChoices(choices);
      }
      if (currentName != null) {
        options['current_name'] = DBusString(currentName);
      }
      if (currentFolder != null) {
        options['current_folder'] = DBusArray.byte(currentFolder);
      }
      if (currentFile != null) {
        options['current_file'] = DBusArray.byte(currentFile);
      }
      var result = await _object.callMethod(
          'org.freedesktop.portal.FileChooser',
          'SaveFile',
          [
            DBusString(parentWindow),
            DBusString(title),
            DBusDict.stringVariant(options)
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    return request.stream.map((result) {
      var urisValue = result['uris'];
      var uris = urisValue?.signature == DBusSignature('as')
          ? urisValue!.asStringArray().toList()
          : <String>[];
      var choicesResult = _decodeChoicesResult(result['choices']);
      var selectedFilter = _decodeFilter(result['current_filter']);

      return XdgFileChooserPortalSaveFileResult(
          uris: uris, choices: choicesResult, currentFilter: selectedFilter);
    });
  }

  /// Ask for a folder as a location to save one or more files.
  Stream<XdgFileChooserPortalSaveFilesResult> saveFiles(
      {required String title,
      String parentWindow = '',
      String? acceptLabel,
      bool? modal,
      Iterable<XdgFileChooserChoice> choices = const [],
      Uint8List? currentFolder,
      Iterable<Uint8List> files = const []}) {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      if (acceptLabel != null) {
        options['accept_label'] = DBusString(acceptLabel);
      }
      if (modal != null) {
        options['modal'] = DBusBoolean(modal);
      }
      if (choices.isNotEmpty) {
        options['choices'] = _encodeChoices(choices);
      }
      if (currentFolder != null) {
        options['current_folder'] = DBusArray.byte(currentFolder);
      }
      if (files.isNotEmpty) {
        options['files'] =
            DBusArray(DBusSignature('ay'), files.map((f) => DBusArray.byte(f)));
      }
      var result = await _object.callMethod(
          'org.freedesktop.portal.FileChooser',
          'SaveFiles',
          [
            DBusString(parentWindow),
            DBusString(title),
            DBusDict.stringVariant(options)
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    return request.stream.map((result) {
      var urisValue = result['uris'];
      var uris = urisValue?.signature == DBusSignature('as')
          ? urisValue!.asStringArray().toList()
          : <String>[];
      var choicesResult = _decodeChoicesResult(result['choices']);

      return XdgFileChooserPortalSaveFilesResult(
          uris: uris, choices: choicesResult);
    });
  }
}
