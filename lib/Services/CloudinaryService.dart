import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dyf2fdypo';
  static const String uploadPreset = 'pashuseva_preset';

  Future<String> uploadImage(File imageFile) async {
    var url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final data = json.decode(resStr);
      return data['secure_url'];
    } else {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  }
}
