import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const IclsVoiceApp());
}

class IclsVoiceApp extends StatelessWidget {
  const IclsVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICLS Voice App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VoiceButtonPage(),
    );
  }
}

class VoiceButtonPage extends StatefulWidget {
  const VoiceButtonPage({super.key});

  @override
  State<VoiceButtonPage> createState() => _VoiceButtonPageState();
}

class _VoiceButtonPageState extends State<VoiceButtonPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _statusMessage = 'ボタンを押して音声を再生';

  // ==========================================
  // 音声ファイルのリスト（日本語ファイル名をそのまま記述）
  // ==========================================
  final List<String> audioFiles = [
    'test.wav',
    '001_青山龍星（ノーマル）_くっ 苦しい 苦しい.wav',
  ];

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.stop();
      
      // 二重エンコードを防ぐため、Uri.encodeComponent は使わずそのまま AssetSource に渡す
      await _audioPlayer.play(AssetSource('audio/$fileName'));
      
      setState(() {
        _statusMessage = '再生中: $fileName';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '再生エラー: $e';
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICLS シミュレーション音声アプリ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: audioFiles.length,
                itemBuilder: (context, index) {
                  final fileName = audioFiles[index];

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => _playSound(fileName),
                    child: Text(
                      fileName,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}