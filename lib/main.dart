import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICLS 患者音声操作パネル',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const VoiceScreen(),
    );
  }
}

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, String>> _audioItems = []; // {'title': '胸が苦しいです', 'path': 'audio/胸が苦しいです.mp3'}
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudioAssets();
  }

  // Assets内の音声ファイルを自動検索してリスト化する関数
  Future<void> _loadAudioAssets() async {
    try {
      // AssetManifestを取得
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // assets/audio/ 配下にある音声ファイルのみ抽出
      final audioPaths = manifestMap.keys.where((String key) {
        return key.startsWith('assets/audio/') &&
            (key.endsWith('.mp3') || key.endsWith('.wav') || key.endsWith('.m4a'));
      }).toList();

      List<Map<String, String>> items = [];

      for (String fullPath in audioPaths) {
        // パスからファイル名のみ抽出 (例: "assets/audio/胸が苦しいです.mp3" -> "胸が苦しいです.mp3")
        String fileName = fullPath.split('/').last;

        // 拡張子を取り除く (例: "胸が苦しいです.mp3" -> "胸が苦しいです")
        String title = fileName.substring(0, fileName.lastIndexOf('.'));

        // audioplayersパッケージで再生するために "assets/" プレフィックスを取り除く
        String cleanPath = fullPath.replaceFirst('assets/', '');

        items.add({
          'title': title,
          'path': cleanPath,
        });
      }

      setState(() {
        _audioItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Assets読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 音声再生関数
  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.stop(); // 連続で押された時に前の音を止めて即再生
      await _audioPlayer.play(AssetSource(path));
    } catch (e) {
      print('再生エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICLS 患者音声コントローラー'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAudioAssets,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _audioItems.isEmpty
              ? const Center(child: Text('assets/audio/ に音声ファイルが見つかりません'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // iPad横画面で見やすい3列配置
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _audioItems.length,
                    itemBuilder: (context, index) {
                      final item = _audioItems[index];
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _playAudio(item['path']!),
                        child: Text(
                          item['title']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}