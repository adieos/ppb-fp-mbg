import 'package:minio/minio.dart';
import 'dart:typed_data';

/// Shared MinIO service.
/// Kitchen owner uses [uploadFile] to upload proof images.
/// Admin uses [getPresignedUrl] to display them.
class MinioService {
  static final MinioService _instance = MinioService._();
  factory MinioService() => _instance;
  MinioService._();

  static const _endpoint  = String.fromEnvironment('MINIO_HOST'); //buat config di .vscode/launch.json
  static const _port      = 9000;
  static const _accessKey = String.fromEnvironment('MINIO_ACCESS_KEY');
  static const _secretKey = String.fromEnvironment('MINIO_SECRET_KEY');
  static const _bucket    = 'mbg';
  static const _useSSL    = false;

  final _client = Minio(
    endPoint:  _endpoint,
    port:      _port,
    useSSL:    _useSSL,
    accessKey: _accessKey,
    secretKey: _secretKey,
  );

  Future<String> getPresignedUrl(String objectPath) async {
    return await _client.presignedGetObject(_bucket, objectPath);
  }

  Future<String> uploadFile({
    required String objectPath,
    required Stream<Uint8List> fileStream,
  }) async {
    await _client.putObject(_bucket, objectPath, fileStream);
    return objectPath;
  }
}
