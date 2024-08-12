import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapApiService {
  final String apiKey = dotenv.env['GOOGLE_MAP_KEY']!;  // 환경변수에서 API 키 로드

  // 현재 위치를 가져와서 Google Static Maps API로 지도를 생성하는 함수
  Future<String> getMapImageUrl(double latitude, double longitude, int i) async {
    // 현재 위치 가져오기
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double latitude = position.latitude;
    double longitude = position.longitude;

    // 이미지 URL을 URL 인코딩
    final markerIconUrl = Uri.encodeComponent('https://i.imgur.com/FXctDhh.png');

    // Google Static Maps API 호출 URL 생성
    final url = 'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=17&size=600x300&maptype=roadmap&markers=icon:$markerIconUrl%7C$latitude,$longitude&key=$apiKey';
    return url;
  }
}
