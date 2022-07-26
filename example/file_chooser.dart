import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  var result = await client.fileChooser.openFile(title: 'Open File', filters: [
    XdgFileChooserFilter('SVG Image', [
      XdgFileChooserGlobPattern('*.svg'),
      XdgFileChooserMimeTypePattern('application/x-svg')
    ]),
    XdgFileChooserFilter('PNG Image', [
      XdgFileChooserGlobPattern('*.png'),
      XdgFileChooserMimeTypePattern('image/png')
    ])
  ], choices: [
    XdgFileChooserChoice(
        id: 'color',
        label: 'Color',
        values: {'red': 'Red', 'green': 'Green', 'blue': 'Blue'},
        initialSelection: 'green'),
    XdgFileChooserChoice(
        id: 'size',
        label: 'Size',
        values: {'small': 'Small', 'medium': 'Medium', 'large': 'Large'})
  ]).first;
  for (var uri in result.uris) {
    print(uri);
  }
  print('Color: ${result.choices['color']}');
  print('Size: ${result.choices['size']}');

  await client.close();
}
