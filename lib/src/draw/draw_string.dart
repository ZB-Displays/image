import '../color/channel.dart';
import '../color/color.dart';
import '../font/bitmap_font.dart';
import '../image/image.dart';
import 'draw_pixel.dart';

enum TextAlignHorizontal { left, right, center }
enum TextAlignVertical { top, bottom, center }

/// Draw a string horizontally into [image] horizontally into [image] at
/// position [x],[y] with the given [color].
/// If [x] and horizontalAlignment is not specified, the string will be centered horizontally.
/// If [y] and verticalAlignment is not specified, the string will be centered vertically.
/// Using horizontal and vertical alignment you can define where the text is anchored (left, center right). The default is top left.
///
/// You can load your own font, or use one of the existing ones
/// such as: arial14, arial24, or arial48.
///  Fonts can be create with a tool such as: https://ttf2fnt.com/
Image drawString(Image image, String string,
    {required BitmapFont font,
    int? x,
    int? y,
    Color? color,
    bool rightJustify = false,
    bool wrap = false,
    Image? mask,
    Channel maskChannel = Channel.luminance,
    TextAlignHorizontal? horizontalAlignment,
    TextAlignVertical? verticalAlignment,
    }) {
  if (color?.a == 0) {
    return image;
  }

  var stringWidth = 0;
  var stringHeight = 0;

  final chars = string.codeUnits;
  for (var c in chars) {
    if (!font.characters.containsKey(c)) {
      continue;
    }
    final ch = font.characters[c]!;
    stringWidth += ch.xAdvance;
    if (ch.height + ch.yOffset > stringHeight) {
      stringHeight = ch.height + ch.yOffset;
    }
  }

  
  if(x == null && horizontalAlignment == null) {
    horizontalAlignment = TextAlignHorizontal.center;
  }

  if(y == null && verticalAlignment == null) {
    verticalAlignment = TextAlignVertical.center;
  }

  switch (horizontalAlignment) {
    default:
    case TextAlignHorizontal.left:
      sx ??= 0;
      break;
    case TextAlignHorizontal.right:
      sx ??= image.width;
      sx = sx - stringWidth;
      break;
    case TextAlignHorizontal.center:
      sx ??= image.width ~/ 2;
      sx = sx - (stringWidth / 2).round();
      break;
  }

  switch (verticalAlignment) {
    default:
    case TextAlignVertical.top:
      sy ??= 0;
      break;
    case TextAlignVertical.bottom:
      sy ??= image.height;
      sy = sy - stringHeight;
      break;
    case TextAlignVertical.center:
      sy ??= image.height ~/ 2;
      sy = sy - (stringHeight / 2).round();
      break;
  }

  if (wrap) {
    final sentences = string.split(RegExp(r'\n'));

    for (var sentence in sentences) {
      final words = sentence.split(RegExp(r"\s+"));
      var subString = "";
      var x2 = sx;

      for (var w in words) {
        final ws = StringBuffer()
          ..write(w)
          ..write(' ');
        w = ws.toString();
        final chars = w.codeUnits;
        var wordWidth = 0;
        for (var c in chars) {
          if (c == 10) break;
          if (!font.characters.containsKey(c)) {
            wordWidth += font.base ~/ 2;
            continue;
          }
          final ch = font.characters[c]!;
          wordWidth += ch.xAdvance;
        }
        if ((x2 + wordWidth) > image.width) {
          // If there is a word that won't fit the starting x, stop drawing
          if ((sx == x2) || (sx + wordWidth > image.width)) {
            return image;
          }

          drawString(image, subString,
              font: font,
              x: sx,
              y: sy,
              color: color,
              mask: mask,
              maskChannel: maskChannel,
              rightJustify: rightJustify);

          subString = "";
          x2 = sx;
          sy += stringHeight;
          subString += w;
          x2 += wordWidth;
        } else {
          subString += w;
          x2 += wordWidth;
        }

        if (subString.isNotEmpty) {
          drawString(image, subString,
              font: font,
              x: sx,
              y: sy,
              color: color,
              mask: mask,
              maskChannel: maskChannel,
              rightJustify: rightJustify);
        }
      }

      sy += stringHeight;
    }

    return image;
  }

  final origX = sx;
  final substrings = string.split(RegExp(r"[\n|\r]"));

  // print(substrings);

  for (var ss in substrings) {
    final chars = ss.codeUnits;
    // print("$ss = $chars");
    if (rightJustify == true) {
      for (var c in chars) {
        if (!font.characters.containsKey(c)) {
          sx -= font.base ~/ 2;
          continue;
        }

        final ch = font.characters[c]!;
        sx -= ch.xAdvance;
      }
    }
    for (var c in chars) {
      if (!font.characters.containsKey(c)) {
        sx += font.base ~/ 2;
        continue;
      }

      final ch = font.characters[c]!;

      final x2 = sx + ch.width;
      final y2 = sy + ch.height;
      final cIter = ch.image.iterator..moveNext();
      for (var yi = sy; yi < y2; ++yi) {
        for (var xi = sx; xi < x2; ++xi, cIter.moveNext()) {
          final p = cIter.current;
          drawPixel(image, xi + ch.xOffset, yi + ch.yOffset, p,
              filter: color, mask: mask, maskChannel: maskChannel);
        }
      }

      sx += ch.xAdvance;
    }

    sy = sy + stringHeight;
    sx = origX;
  }

  return image;
}
